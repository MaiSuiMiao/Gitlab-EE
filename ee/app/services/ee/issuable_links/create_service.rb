# frozen_string_literal: true

module EE
  module IssuableLinks
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :link_issuables
      def link_issuables(objects)
        # it is important that this is not called after relate_issuables, as it relinks epic to the issuable
        # relate_issuables is called during the `super` portion of this method
        # see EpicLinks::EpicIssues#relate_issuables
        affected_epics = affected_epics(objects)

        super

        if !params[:skip_epic_dates_update] && affected_epics.present?
          Epics::UpdateDatesService.new(affected_epics).execute
        end
      end

      def affected_epics(_issues)
        []
      end

      override :set_link_type
      def set_link_type(link)
        return unless params[:link_type].present?

        # `blocked_by` links are treated as `blocks` links where source and target is swapped.
        if params[:link_type] == ::IssuableLink::TYPE_IS_BLOCKED_BY
          link.source, link.target = link.target, link.source
          link.link_type = ::IssuableLink::TYPE_BLOCKS
        else
          link.link_type = params[:link_type]
        end
      end
    end
  end
end
