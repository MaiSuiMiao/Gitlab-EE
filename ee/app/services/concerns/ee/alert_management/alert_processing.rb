# frozen_string_literal: true

module EE
  module AlertManagement
    module AlertProcessing
      extend ::Gitlab::Utils::Override

      private

      override :complete_post_processing_tasks
      def complete_post_processing_tasks
        super

        notify_oncall if oncall_notification_recipients.present? && notifying_alert?
        process_escalations
      end

      def process_escalations
        if alert.resolved? || alert.ignored?
          delete_pending_escalations
        else
          create_pending_escalations
        end
      end

      def notify_oncall
        notification_service
          .async
          .notify_oncall_users_of_alert(oncall_notification_recipients.to_a, alert)
      end

      def oncall_notification_recipients
        strong_memoize(:oncall_notification_recipients) do
          ::IncidentManagement::OncallUsersFinder.new(project).execute
        end
      end

      def delete_pending_escalations
        # We use :delete_all here to avoid null constraint errors. (the default is :nullify).
        alert.pending_escalations.delete_all(:delete_all)
      end

      def create_pending_escalations
        ::IncidentManagement::PendingEscalations::CreateService.new(alert).execute
      end
    end
  end
end
