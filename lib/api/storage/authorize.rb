# frozen_string_literal: true

module API
  module Storage
    class Authorize < ::API::Base
      helpers do
        def upload_url
          headers['Workhorse-Upload-Url']
        end

        def handle_authorize
          bad_request!("No upload url set") unless upload_url

          authorizer = ::Gitlab::Storage::Authorizer.registry.find_authorizer_for(upload_url)

          bad_request!("Can't find an authorizer for #{upload_url}") unless authorizer

          status 200
          content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

          authorizer.authorize!(self, upload_url)
        end
      end

      after_validation do
        require_gitlab_workhorse!
      end

      put 'gitlab/storage/authorize' do
        handle_authorize
      end

      post 'gitlab/storage/authorize' do
        handle_authorize
      end
    end
  end
end
