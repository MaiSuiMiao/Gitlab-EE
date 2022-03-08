# frozen_string_literal: true

module Security
  module TrainingProviders
    class SecureCodeWarriorUrlFinder < BaseUrlFinder
      def calculate_reactive_cache(full_url)
        response = Gitlab::HTTP.try_get(full_url)
        { url: response.parsed_response["url"] } if response
      end

      def full_url
        Gitlab::Utils.append_path(provider.url, "?Id=gitlab&MappingList=#{identifier.external_type}&MappingKey=#{identifier.external_id}")
      end
    end
  end
end
