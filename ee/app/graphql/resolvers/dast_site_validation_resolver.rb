# frozen_string_literal: true

module Resolvers
  class DastSiteValidationResolver < BaseResolver
    alias_method :project, :synchronized_object

    type Types::DastSiteValidationType.connection_type, null: true

    argument :normalized_target_urls, [GraphQL::STRING_TYPE], required: false,
             description: 'Normalized URL of the target to be scanned.'

    def resolve(**args)
      return DastSiteValidation.none unless allowed?

      DastSiteValidationsFinder.new(project_id: project.id, url_base: args[:normalized_target_urls], most_recent: true).execute
    end

    private

    def allowed?
      ::Feature.enabled?(:security_on_demand_scans_site_validation, project, default_enabled: :yaml)
    end
  end
end
