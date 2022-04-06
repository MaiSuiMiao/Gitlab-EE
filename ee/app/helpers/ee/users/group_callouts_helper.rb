# frozen_string_literal: true

module EE
  module Users
    module GroupCalloutsHelper
      extend ::Gitlab::Utils::Override

      PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT = 'preview_user_over_limit_free_plan_alert'
      USER_REACHED_LIMIT_FREE_PLAN_ALERT = 'user_reached_limit_free_plan_alert'

      def show_preview_user_over_limit_free_plan_alert?(namespace)
        return false if namespace.user_namespace?
        return false if user_dismissed_for_group(PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT, namespace, 14.days.ago)
        return false unless Ability.allowed?(current_user, :owner_access, namespace)

        ::Namespaces::PreviewFreeUserCap.new(namespace).over_limit?
      end

      def show_user_reached_limit_free_plan_alert?(namespace)
        return false if namespace.user_namespace?
        return false if user_dismissed_for_group(USER_REACHED_LIMIT_FREE_PLAN_ALERT, namespace)
        return false unless Ability.allowed?(current_user, :owner_access, namespace)

        ::Namespaces::FreeUserCap.new(namespace).reached_limit?
      end
    end
  end
end
