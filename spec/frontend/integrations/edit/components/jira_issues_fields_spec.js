import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import eventHub from '~/integrations/edit/event_hub';
import { createStore } from '~/integrations/edit/store';

describe('JiraIssuesFields', () => {
  let store;
  let wrapper;

  const defaultProps = {
    editProjectPath: '/edit',
    showJiraIssuesIntegration: true,
    showJiraVulnerabilitiesIntegration: true,
    upgradePlanPath: 'https://gitlab.com',
  };

  const createComponent = ({ isInheriting = false, props, ...options } = {}) => {
    store = createStore({
      defaultState: isInheriting ? {} : undefined,
    });

    wrapper = mountExtended(JiraIssuesFields, {
      propsData: { ...defaultProps, ...props },
      store,
      stubs: ['jira-issue-creation-vulnerabilities'],
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findEnableCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findEnableCheckboxDisabled = () =>
    findEnableCheckbox().find('[type=checkbox]').attributes('disabled');
  const findProjectKey = () => wrapper.findComponent(GlFormInput);
  const findPremiumUpgradeCTA = () => wrapper.findByTestId('premium-upgrade-cta');
  const findUltimateUpgradeCTA = () => wrapper.findByTestId('ultimate-upgrade-cta');
  const findJiraForVulnerabilities = () => wrapper.findByTestId('jira-for-vulnerabilities');
  const setEnableCheckbox = async (isEnabled = true) =>
    findEnableCheckbox().vm.$emit('input', isEnabled);

  describe('template', () => {
    describe('when `showJiraIssuesIntegration` is false', () => {
      beforeEach(() => {
        createComponent({
          props: { showJiraIssuesIntegration: false },
        });
      });

      it('shows the premium CTA', () => {
        const premiumUpgradeCTA = findPremiumUpgradeCTA();

        expect(premiumUpgradeCTA.exists()).toBe(true);
        expect(premiumUpgradeCTA.props('upgradePlanPath')).toBe(defaultProps.upgradePlanPath);
      });

      it('does not show checkbox and input field', () => {
        expect(findEnableCheckbox().exists()).toBe(false);
        expect(findProjectKey().exists()).toBe(false);
      });
    });

    describe('when `showJiraIssuesIntegration` is true and `showJiraVulnerabilitiesIntegration` is false', () => {
      beforeEach(() => {
        createComponent({
          props: { showJiraIssuesIntegration: true, showJiraVulnerabilitiesIntegration: false },
        });
      });

      it('renders "Enable Jira Issues" checkbox', () => {
        expect(findEnableCheckbox().exists()).toBe(true);
        expect(findEnableCheckboxDisabled()).toBeUndefined();
      });

      it.each`
        scenario                                                                        | enableJiraIssues
        ${'when "Enable Jira Issues" is checked, shows ultimate upgrade CTA'}           | ${true}
        ${'when "Enable Jira Issues" is unchecked, does not show ultimate upgrade CTA'} | ${false}
      `('$scenario', async ({ enableJiraIssues }) => {
        createComponent({
          props: { showJiraIssuesIntegration: true, showJiraVulnerabilitiesIntegration: false },
        });

        if (enableJiraIssues) {
          await setEnableCheckbox();
        }

        expect(findPremiumUpgradeCTA().exists()).toBe(false);
        expect(findUltimateUpgradeCTA().exists()).toBe(enableJiraIssues);
      });
    });

    describe('when `showJiraIssuesIntegration` is true and `showJiraVulnerabilitiesIntegration` is true', () => {
      it('does not show any upgrade CTA', () => {
        createComponent({
          props: { showJiraIssuesIntegration: true, showJiraVulnerabilitiesIntegration: true },
        });

        expect(findPremiumUpgradeCTA().exists()).toBe(false);
        expect(findUltimateUpgradeCTA().exists()).toBe(false);
      });
    });

    describe('Enable Jira issues checkbox', () => {
      beforeEach(() => {
        createComponent({ props: { initialProjectKey: '' } });
      });

      it('renders disabled project_key input', () => {
        const projectKey = findProjectKey();

        expect(projectKey.exists()).toBe(true);
        expect(projectKey.attributes('disabled')).toBe('disabled');
        expect(projectKey.attributes('required')).toBeUndefined();
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes issues_enabled as false even if unchecked', () => {
        expect(wrapper.find('input[name="service[issues_enabled]"]').exists()).toBe(true);
      });

      describe('when isInheriting = true', () => {
        it('disables checkbox and sets input as readonly', () => {
          createComponent({ isInheriting: true });

          expect(findEnableCheckboxDisabled()).toBe('disabled');
          expect(findProjectKey().attributes('readonly')).toBe('readonly');
        });
      });

      describe('on enable issues', () => {
        it('enables project_key input as required', async () => {
          await setEnableCheckbox(true);

          expect(findProjectKey().attributes('disabled')).toBeUndefined();
          expect(findProjectKey().attributes('required')).toBe('required');
        });
      });
    });

    it('contains link to editProjectPath', () => {
      createComponent();

      expect(wrapper.find(`a[href="${defaultProps.editProjectPath}"]`).exists()).toBe(true);
    });

    describe('GitLab issues warning', () => {
      const expectedText = 'Consider disabling GitLab issues';

      it('contains warning when GitLab issues is enabled', () => {
        createComponent();

        expect(wrapper.text()).toContain(expectedText);
      });

      it('does not contain warning when GitLab issues is disabled', () => {
        createComponent({ props: { gitlabIssuesEnabled: false } });

        expect(wrapper.text()).not.toContain(expectedText);
      });
    });

    describe('Vulnerabilities creation', () => {
      beforeEach(() => {
        createComponent();
      });

      it.each([true, false])(
        'shows the jira-vulnerabilities component correctly when jira issues enables is set to "%s"',
        async (hasJiraIssuesEnabled) => {
          await setEnableCheckbox(hasJiraIssuesEnabled);

          expect(findJiraForVulnerabilities().exists()).toBe(hasJiraIssuesEnabled);
        },
      );

      it('passes down the correct show-full-feature property', async () => {
        await setEnableCheckbox(true);
        expect(findJiraForVulnerabilities().attributes('show-full-feature')).toBe('true');
        wrapper.setProps({ showJiraVulnerabilitiesIntegration: false });
        await wrapper.vm.$nextTick();
        expect(findJiraForVulnerabilities().attributes('show-full-feature')).toBeUndefined();
      });

      it('passes down the correct initial-issue-type-id value when value is empty', async () => {
        await setEnableCheckbox(true);
        expect(findJiraForVulnerabilities().attributes('initial-issue-type-id')).toBeUndefined();
      });

      it('passes down the correct initial-issue-type-id value when value is not empty', async () => {
        const jiraIssueType = 'some-jira-issue-type';
        wrapper.setProps({ initialVulnerabilitiesIssuetype: jiraIssueType });
        await setEnableCheckbox(true);
        expect(findJiraForVulnerabilities().attributes('initial-issue-type-id')).toBe(
          jiraIssueType,
        );
      });

      it('emits "getJiraIssueTypes" to the eventHub when the jira-vulnerabilities component requests to fetch issue types', async () => {
        const eventHubEmitSpy = jest.spyOn(eventHub, '$emit');

        await setEnableCheckbox(true);
        await findJiraForVulnerabilities().vm.$emit('request-get-issue-types');

        expect(eventHubEmitSpy).toHaveBeenCalledWith('getJiraIssueTypes');
      });
    });
  });
});
