# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::RegisterRunnerService, '#execute' do
  let(:registration_token) { 'abcdefg123456' }
  let(:token) { }
  let(:audit_service) { instance_double(::AuditEvents::RunnerRegistrationAuditEventService) }

  before do
    stub_feature_flags(runner_registration_control: false)
    stub_application_setting(runners_registration_token: registration_token)
    stub_application_setting(valid_runner_registrars: ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)

    expect(audit_service).to receive(:track_event).once.and_return('track_event_return_value')
  end

  subject { described_class.new.execute(token, {}) }

  RSpec::Matchers.define :last_ci_runner do
    match { |runner| runner == ::Ci::Runner.last }
  end

  RSpec::Matchers.define :a_ci_runner_with_errors do
    match { |runner| runner.errors.any? }
  end

  shared_examples 'a service logging a runner registration audit event' do
    it 'returns newly-created Runner' do
      expect(::AuditEvents::RunnerRegistrationAuditEventService).to receive(:new)
        .with(last_ci_runner, token, token_scope, :register)
        .once.and_return(audit_service)

      is_expected.to eq(::Ci::Runner.last)
    end
  end

  shared_examples 'a service logging a failed runner registration audit event' do
    before do
      expect(::AuditEvents::RunnerRegistrationAuditEventService).to receive(:new)
        .with(a_ci_runner_with_errors, token, token_scope, :register)
        .once.and_return(audit_service)
    end

    it 'returns a Runner' do
      is_expected.to be_a ::Ci::Runner
    end

    it 'returns a non-persisted Runner' do
      expect(subject.persisted?).to be_falsey
    end
  end

  context 'with a registration token' do
    let(:token) { registration_token }
    let(:token_scope) { }

    it_behaves_like 'a service logging a runner registration audit event'
  end

  context 'when project token is used' do
    let(:project) { create(:project) }
    let(:token) { project.runners_token }
    let(:token_scope) { project }

    it_behaves_like 'a service logging a runner registration audit event'

    context 'when it exceeds the application limits' do
      before do
        create(:ci_runner, runner_type: :project_type, projects: [project], contacted_at: 1.second.ago)
        create(:plan_limits, :default_plan, ci_registered_project_runners: 1)
      end

      it_behaves_like 'a service logging a failed runner registration audit event'
    end
  end

  context 'when group token is used' do
    let(:group) { create(:group) }
    let(:token) { group.runners_token }
    let(:token_scope) { group }

    it_behaves_like 'a service logging a runner registration audit event'

    context 'when it exceeds the application limits' do
      before do
        create(:ci_runner, runner_type: :group_type, groups: [group], contacted_at: 1.second.ago)
        create(:plan_limits, :default_plan, ci_registered_group_runners: 1)
      end

      it_behaves_like 'a service logging a failed runner registration audit event'
    end
  end
end