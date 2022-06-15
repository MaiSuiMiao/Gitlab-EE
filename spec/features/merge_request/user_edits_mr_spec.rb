# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits MR' do
  include ProjectForksHelper

  before do
    stub_licensed_features(multiple_merge_request_assignees: false)
  end

  context 'with the visible_label_selection_on_metadata feature flag enabled' do
    before do
      stub_feature_flags(visible_label_selection_on_metadata: true)
    end

    context 'non-fork merge request' do
      include_context 'merge request edit context'
      it_behaves_like 'an editable merge request with visible selected labels'
    end

    context 'for a forked project' do
      let(:source_project) { fork_project(target_project, nil, repository: true) }

      include_context 'merge request edit context'
      it_behaves_like 'an editable merge request with visible selected labels'
    end
  end

  context 'with the visible_label_selection_on_metadata feature flag disabled' do
    before do
      stub_feature_flags(visible_label_selection_on_metadata: false)
    end

    context 'non-fork merge request' do
      include_context 'merge request edit context'
      it_behaves_like 'an editable merge request'
    end

    context 'for a forked project' do
      let(:source_project) { fork_project(target_project, nil, repository: true) }

      include_context 'merge request edit context'
      it_behaves_like 'an editable merge request'
    end
  end
end
