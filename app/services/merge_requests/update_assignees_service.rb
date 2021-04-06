# frozen_string_literal: true

module MergeRequests
  class UpdateAssigneesService < UpdateService
    # a stripped down service that only does what it must to update the
    # assignees, and knows that it does not have to check for other updates.
    # This saves a lot of queries for irrelevant things that cannot possibly
    # change in the execution of this service.
    def execute(merge_request)
      return merge_request unless current_user&.can?(:update_merge_request, merge_request)

      old_ids = merge_request.assignees.map(&:id)
      new_ids = new_assignee_ids(merge_request)
      return merge_request if old_ids.to_set == new_ids.to_set # no-change

      attrs = update_attrs.merge(assignee_ids: new_ids)
      merge_request.update!(**attrs)

      # Defer the more expensive operations (handle_assignee_changes) to the background
      MergeRequests::AssigneesChangeWorker.perform_async(merge_request.id, current_user.id, old_ids)

      merge_request
    end

    def handle_assignee_changes(merge_request, old_assignees)
      # exposes private method from super-class
      users = old_assignees.to_a
      handle_assignees_change(merge_request, users)
      execute_hooks(
        merge_request,
        'update',
        old_associations: { assignees: users }
      )
    end

    private

    def new_assignee_ids(merge_request)
      User.id_in(update_attrs[:assignee_ids]).map do |user|
        user.id if user.can?(:read_merge_request, merge_request)
      end.compact
    end

    def assignee_ids
      params.fetch(:assignee_ids).first(1)
    end

    def update_attrs
      @attrs ||= { updated_at: Time.current, updated_by: current_user, assignee_ids: assignee_ids }
    end
  end
end

MergeRequests::UpdateAssigneesService.prepend_if_ee('EE::MergeRequests::UpdateAssigneesService')
