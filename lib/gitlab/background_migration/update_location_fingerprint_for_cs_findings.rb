# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class UpdateLocationFingerprintForCsFindings
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::UpdateLocationFingerprintForCsFindings.prepend_if_ee('EE::Gitlab::BackgroundMigration::UpdateLocationFingerprintForCsFindings')
