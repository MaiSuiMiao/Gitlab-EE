# frozen_string_literal: true

class Packages::Attachment < ActiveStorage::Attachment
  self.table_name = 'packages_attachments'

  belongs_to :blob, class_name: 'Packages::Blob', autosave: true
end
