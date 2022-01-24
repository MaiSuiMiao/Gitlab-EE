# frozen_string_literal: true
require "active_storage/service/s3_service"

module ActiveStorage
  class Service
    # The location of third party services is fixed: ActiveStorage::Service
    class GitlabS3Service < ::ActiveStorage::Service::S3Service
      # Override of the original method so that only the host header is signed instead of
      # host + content_type + content_length
      def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
        instrument :url, key: key do |payload|
          generated_url = object_for(key).presigned_url :put, expires_in: expires_in.to_i, content_md5: checksum,
                                                        metadata: custom_metadata, **upload_options

          payload[:url] = generated_url

          generated_url
        end
      end
    end
  end
end
