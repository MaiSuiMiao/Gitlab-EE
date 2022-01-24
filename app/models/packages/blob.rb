# frozen_string_literal: true

class Packages::Blob < ActiveStorage::Blob
  self.table_name = 'packages_blobs'

  has_many :attachments, class_name: 'Packages::Attachment'

  # overrides
  has_many :variant_records, dependent: false
  has_one :preview_image_attachment, class_name: 'Packages::Attachment', dependent: false

  def self.create_before_direct_upload!(filename: '', content_type: '')
    super(filename: filename, byte_size: 0, checksum: nil, service_name: :packages, content_type: content_type)
  end

  class << self
    def generate_unique_secure_token(length: self::MINIMUM_TOKEN_LENGTH)
      Gitlab::HashedPath.new(super, root_hash: super).to_s
    end
  end
end
