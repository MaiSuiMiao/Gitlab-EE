# coding: utf-8
require 'spec_helper'

describe PostReceive do
  let(:changes) { "123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }
  let(:wrongly_encoded_changes) { changes.encode("ISO-8859-1").force_encoding("UTF-8") }
  let(:base64_changes) { Base64.encode64(wrongly_encoded_changes) }
  let(:gl_repository) { "project-#{project.id}" }
  let(:key) { create(:key, user: project.owner) }
  let(:key_id) { key.shell_id }
  let(:project) { create(:project, :repository, :wiki_repo) }

  describe "#process_project_changes" do
    before do
      allow_any_instance_of(Gitlab::GitPostReceive).to receive(:identify).and_return(project.owner)
    end

    context 'after project changes hooks' do
      let(:fake_hook_data) { Hash.new(event_name: 'repository_update') }

      before do
        allow_any_instance_of(Gitlab::DataBuilder::Repository).to receive(:update).and_return(fake_hook_data)
        # silence hooks so we can isolate
        allow_any_instance_of(Key).to receive(:post_create_hook).and_return(true)

        expect_next_instance_of(Git::TagPushService) do |service|
          expect(service).to receive(:execute).and_return(true)
        end

        expect_next_instance_of(Git::BranchPushService) do |service|
          expect(service).to receive(:execute).and_return(true)
        end
      end

      it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node' do
        allow(Gitlab::Geo).to receive(:primary?) { true }

        expect_any_instance_of(::Geo::RepositoryUpdatedService).to receive(:execute)

        described_class.new.perform(gl_repository, key_id, base64_changes)
      end

      it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node' do
        allow(Gitlab::Geo).to receive(:primary?) { false }

        expect_any_instance_of(::Geo::RepositoryUpdatedService).not_to receive(:execute)

        described_class.new.perform(gl_repository, key_id, base64_changes)
      end
    end
  end

  describe '#process_wiki_changes' do
    let(:gl_repository) { "wiki-#{project.id}" }

    it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { true }

      expect_any_instance_of(::Geo::RepositoryUpdatedService).to receive(:execute)

      described_class.new.perform(gl_repository, key_id, base64_changes)
    end

    it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect_any_instance_of(::Geo::RepositoryUpdatedService).not_to receive(:execute)

      described_class.new.perform(gl_repository, key_id, base64_changes)
    end

    it 'triggers wiki index update when ElasticSearch is enabled', :elastic do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

      expect_any_instance_of(ProjectWiki).to receive(:index_wiki_blobs)

      described_class.new.perform(gl_repository, key_id, base64_changes)
    end

    context 'when limited indexing is on', :elastic do
      before do
        stub_ee_application_setting(
          elasticsearch_search: true,
          elasticsearch_indexing: true,
          elasticsearch_limit_indexing: true
        )
      end

      context 'when the project is not enabled specifically' do
        it 'does not trigger wiki index update' do
          expect_any_instance_of(ProjectWiki).not_to receive(:index_wiki_blobs)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end

      context 'when a project is enabled specifically' do
        before do
          create :elasticsearch_indexed_project, project: project
        end

        it 'triggers wiki index update' do
          expect_any_instance_of(ProjectWiki).to receive(:index_wiki_blobs)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end

      context 'when a group is enabled' do
        let(:group) { create(:group) }
        let(:project) { create(:project, :wiki_repo, group: group) }
        let(:key) { create(:key, user: group.owner) }

        before do
          create :elasticsearch_indexed_namespace, namespace: group
        end

        it 'triggers wiki index update' do
          expect_any_instance_of(ProjectWiki).to receive(:index_wiki_blobs)

          described_class.new.perform(gl_repository, key_id, base64_changes)
        end
      end
    end
  end

  describe 'processing design changes' do
    let(:gl_repository) { "design-#{project.id}" }

    it 'does not do anything' do
      worker = described_class.new

      expect(worker).not_to receive(:process_wiki_changes)
      expect(worker).not_to receive(:process_project_changes)

      described_class.new.perform(gl_repository, key_id, base64_changes)
    end
  end
end
