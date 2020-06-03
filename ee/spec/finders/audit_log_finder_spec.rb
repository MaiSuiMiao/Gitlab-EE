# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditLogFinder do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:subproject) { create(:project, namespace: subgroup) }

  let_it_be(:user_audit_event) { create(:user_audit_event, created_at: 3.days.ago) }
  let_it_be(:project_audit_event) { create(:project_audit_event, entity_id: project.id, created_at: 2.days.ago) }
  let_it_be(:subproject_audit_event) { create(:project_audit_event, entity_id: subproject.id, created_at: 2.days.ago) }
  let_it_be(:group_audit_event) { create(:group_audit_event, entity_id: group.id, created_at: 1.day.ago) }

  let(:level) { Gitlab::Audit::Levels::Instance.new }
  let(:params) { {} }

  subject(:finder) { described_class.new(level: level, params: params) }

  describe '#execute' do
    subject { finder.execute }

    shared_examples 'no filtering' do
      it 'finds all the events' do
        expect(subject.count).to eq(4)
      end
    end

    context 'filtering by level' do
      context 'when project level' do
        let(:level) { Gitlab::Audit::Levels::Project.new(project: project) }

        it 'finds all project events' do
          expect(subject).to contain_exactly(project_audit_event)
        end
      end

      context 'when group level' do
        context 'when audit_log_group_level feature enabled' do
          before do
            stub_feature_flags(audit_log_group_level: true)
          end

          let(:level) { Gitlab::Audit::Levels::Group.new(group: group) }

          it 'finds all group and project events' do
            expect(subject).to contain_exactly(project_audit_event, subproject_audit_event, group_audit_event)
          end
        end

        context 'when audit_log_group_level feature disabled' do
          before do
            stub_feature_flags(audit_log_group_level: false)
          end

          let(:level) { Gitlab::Audit::Levels::Group.new(group: group) }

          it 'finds all group events' do
            expect(subject).to contain_exactly(group_audit_event)
          end
        end
      end

      context 'when instance level' do
        let(:level) { Gitlab::Audit::Levels::Instance.new }

        it 'finds all instance level events' do
          expect(subject).to contain_exactly(
            project_audit_event,
            subproject_audit_event,
            group_audit_event,
            user_audit_event
          )
        end
      end

      context 'when invalid level' do
        let(:level) { 'an invalid level' }

        it 'raises exception' do
          expect { subject }.to raise_error(described_class::InvalidLevelTypeError)
        end
      end
    end

    context 'filtering by entity_id' do
      context 'no entity_type provided' do
        let(:params) { { entity_id: 1 } }

        it_behaves_like 'no filtering'
      end

      context 'invalid entity_id' do
        let(:params) { { entity_type: 'User', entity_id: '0' } }

        it 'ignores entity_id and returns all events for given entity_type' do
          expect(subject.count).to eq(1)
        end
      end

      shared_examples 'finds the right event' do
        it 'finds the right event' do
          expect(subject.count).to eq(1)

          entity = subject.first

          expect(entity.entity_type).to eq(entity_type)
          expect(entity.id).to eq(audit_event.id)
        end
      end

      context 'User Event' do
        let(:params) { { entity_type: 'User', entity_id: user_audit_event.entity_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'User' }
          let(:audit_event) { user_audit_event }
        end
      end

      context 'Project Event' do
        let(:params) { { entity_type: 'Project', entity_id: project_audit_event.entity_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Project' }
          let(:audit_event) { project_audit_event }
        end
      end

      context 'Group Event' do
        let(:params) { { entity_type: 'Group', entity_id: group_audit_event.entity_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Group' }
          let(:audit_event) { group_audit_event }
        end
      end
    end

    context 'filtering by entity_type' do
      let(:entity_types) { subject.map(&:entity_type) }

      context 'User Event' do
        let(:params) { { entity_type: 'User' } }

        it 'finds the right user event' do
          expect(entity_types).to all(eq 'User')
        end
      end

      context 'Project Event' do
        let(:params) { { entity_type: 'Project' } }

        it 'finds the right project event' do
          expect(entity_types).to all(eq 'Project')
        end
      end

      context 'Group Event' do
        let(:params) { { entity_type: 'Group' } }

        it 'finds the right group event' do
          expect(entity_types).to all(eq 'Group')
        end
      end

      context 'invalid entity types' do
        context 'blank entity_type' do
          let(:params) { { entity_type: '' } }

          it_behaves_like 'no filtering'
        end

        context 'invalid entity_type' do
          let(:params) { { entity_type: 'Invalid Entity Type' } }

          it_behaves_like 'no filtering'
        end
      end
    end

    context 'filtering by created_at' do
      context 'through created_after' do
        let(:params) { { created_after: group_audit_event.created_at } }

        it 'returns events created on or after the given date' do
          expect(subject).to contain_exactly(group_audit_event)
        end
      end

      context 'through created_before' do
        let(:params) { { created_before: user_audit_event.created_at } }

        it 'returns events created on or before the given date' do
          expect(subject).to contain_exactly(user_audit_event)
        end
      end

      context 'through created_after and created_before' do
        let(:params) { { created_after: user_audit_event.created_at, created_before: project_audit_event.created_at } }

        it 'returns events created between the given dates' do
          expect(subject).to contain_exactly(user_audit_event, project_audit_event)
        end
      end
    end
  end

  describe '#find_by!' do
    let(:id) { user_audit_event.id }

    subject { finder.find_by!(id: id) }

    it { is_expected.to eq(user_audit_event) }

    context 'non-existent id provided' do
      let(:id) { 'non-existent-id' }

      it 'raises exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
