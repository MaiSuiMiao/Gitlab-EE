# frozen_string_literal: true

module Gitlab
  module Storage
    module Authorizer
      class Base
        API_VERSION = 'v4'

        def match?(url)
          raise NotImplementedError
        end

        def authorize!
          raise NotImplementedError
        end

        private

        def api_pattern(raw_pattern)
          raw_pattern = "/#{raw_pattern}" unless raw_pattern.starts_with?('/')

          pattern = "/api/#{API_VERSION}#{raw_pattern}"

          ::Grape::Router::Pattern.new(pattern)
        end
      end
    end
  end
end
