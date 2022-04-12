# frozen_string_literal: true

module Gitlab
  module Storage
    module Authorizer
      class Registry
        def initialize
          @adapters = ::Gitlab::Storage::Authorizer::Base.descendants.map(&:new)
        end

        def find_authorizer_for(url)
          @adapters.find { |a| a.match?(url) }
        end
      end
    end
  end
end
