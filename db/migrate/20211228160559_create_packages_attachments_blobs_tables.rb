# frozen_string_literal: true

class CreatePackagesAttachmentsBlobsTables < Gitlab::Database::Migration[1.0]
  def up
    create_table :packages_blobs do |t|
      t.text   :key,          null: false, limit: 255
      t.text   :filename,     null: false, limit: 255
      t.text   :content_type, limit: 255
      t.text   :metadata, limit: 255
      t.text   :service_name, null: false, limit: 255
      t.bigint :byte_size, default: 0, null: false
      t.text   :checksum, limit: 255
      t.text   :sha256_checksum, limit: 255
      t.text   :sha512_checksum, limit: 255
      t.datetime_with_timezone :created_at, null: false

      t.index [:key], unique: true
    end

    create_table :packages_attachments do |t|
      t.text     :name, null: false, limit: 255
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false
      t.datetime_with_timezone :created_at, null: false

      t.index [:record_type, :record_id, :name, :blob_id], name: "index_package_attachments_uniqueness", unique: true
      t.foreign_key :packages_blobs, column: :blob_id
    end
  end

  def down
    drop_table :packages_attachments
    drop_table :packages_blobs
  end
end
