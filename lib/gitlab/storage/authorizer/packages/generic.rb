# frozen_string_literal: true

module Gitlab
  module Storage
    module Authorizer
      module Packages
        class Generic < ::Gitlab::Storage::Authorizer::Base
          def match?(relative_url)
            api_pattern('projects/:id/packages/generic').match?(relative_url)
          end

          def authorize!(api, relative_url)
            id = api_pattern('projects/:id/packages/generic').params(relative_url)['id']
            api.bad_request! unless id

            project = Project.find(id)
            user = api.find_user_from_personal_access_token
            api.forbidden! unless api.can?(user, :create_package, project)

            ::Packages::PackageFileUploader.workhorse_authorize(
              has_length: true,
              maximum_size: project.actual_limits.generic_packages_max_file_size
            )
          end
        end
      end
    end
  end
end
