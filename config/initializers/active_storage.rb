# frozen_string_literal: true

Rails.application.configure do
  config.active_storage.draw_routes = false
  config.active_storage.previewers = []
  config.active_storage.analyzers = []
  config.active_storage.track_variants = false
  config.active_storage.service_configurations ||= {}

  # Bad
  if Gitlab.config.packages.enabled
    os = Gitlab.config.packages.object_store

    params = if os.enabled
               {
                 service: 'GitlabS3',
                 access_key_id: os.connection.aws_access_key_id,
                 secret_access_key: os.connection.aws_secret_access_key,
                 bucket: os.remote_directory,
                 region: os.connection.region,
                 endpoint: os.connection.endpoint,
                 force_path_style: os.connection.path_style
               }
             else
               {
                 service: 'Disk',
                 root: Gitlab.config.packages.storage_path
               }
             end

    config.active_storage.service_configurations[:packages] = params
  end
end

module ActiveStorage
  module Attached::Model
    extend ActiveSupport::Concern

    class_methods do
      def has_one_file_attached(name, dependent: :purge_later, service: nil, strict_loading: false)
        validate_service_configuration(name, service)

        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          # frozen_string_literal: true
          def #{name}
            @active_storage_attached ||= {}
            @active_storage_attached[:#{name}] ||= ActiveStorage::Attached::One.new("#{name}", self)
          end
          def #{name}=(attachable)
            attachment_changes["#{name}"] =
              if attachable.nil?
                ActiveStorage::Attached::Changes::DeleteOne.new("#{name}", self)
              else
                ActiveStorage::Attached::Changes::CreateOne.new("#{name}", self, attachable)
              end
          end
        CODE

        has_one :"#{name}_attachment", -> { where(name: name) }, class_name: "#{service.to_s.camelize}::Attachment", as: :record, inverse_of: :record, dependent: :destroy, strict_loading: strict_loading
        has_one :"#{name}_blob", through: :"#{name}_attachment", class_name: "#{service.to_s.camelize}::Blob", source: :blob, strict_loading: strict_loading

        scope :"with_attached_#{name}", -> { includes("#{name}_attachment": :blob) }

        after_save { attachment_changes[name.to_s]&.save }

        after_commit(on: %i[create update]) { attachment_changes.delete(name.to_s).try(:upload) }

        reflection = ActiveRecord::Reflection.create(
          :has_one_attached,
          name,
          nil,
          { dependent: dependent, service_name: service },
          self
        )
        yield reflection if block_given?
        ActiveRecord::Reflection.add_attachment_reflection(self, name, reflection)
      end
    end
  end
end

# overrides
module ActiveStorage
  class Attached::Changes::CreateOne
    private

    def build_attachment
      attachment_class.new(record: record, name: name, blob: blob)
    end

    def find_or_build_blob
      case attachable
      when blob_class
        attachable
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
        blob_class.build_after_unfurling(
          io: attachable.open,
          filename: attachable.original_filename,
          content_type: attachable.content_type,
          record: record,
          service_name: attachment_service_name
        )
      when Hash
        blob_class.build_after_unfurling(
          **attachable.reverse_merge(
            record: record,
            service_name: attachment_service_name
          ).symbolize_keys
        )
      when String
        blob_class.find_signed!(attachable, record: record)
      else
        super
      end
    end

    def attachment_class
      "#{attachment_service_name.to_s.camelize}::Attachment".safe_constantize
    end

    def blob_class
      "#{attachment_service_name.to_s.camelize}::Blob".safe_constantize
    end
  end
end
