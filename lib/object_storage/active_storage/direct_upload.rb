# frozen_string_literal: true

module ObjectStorage
  module ActiveStorage
    class DirectUpload
      def initialize(blob_class:)
        @blob_class = blob_class
      end

      def to_hash
        blob = generate_blob
        {
          StoreURL: blob.service_url_for_direct_upload,
          BlobSignedId: blob.signed_id
        }
      end

      private

      def generate_blob
        @blob_class.create_before_direct_upload!
      end
    end
  end
end
