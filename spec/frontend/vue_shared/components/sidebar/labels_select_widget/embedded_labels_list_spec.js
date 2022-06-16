import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmbeddedLabelsList from '~/vue_shared/components/sidebar/labels_select_widget/embedded_labels_list.vue';
import { mockRegularLabel, mockScopedLabel } from './mock_data';

describe('EmbeddedLabelsList', () => {
  let wrapper;

  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findRegularLabel = () => findAllLabels().at(1);
  const findScopedLabel = () => findAllLabels().at(0);
  const findWrapper = () => wrapper.findByTestId('embedded-labels-list');

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMountExtended(EmbeddedLabelsList, {
      slots,
      propsData: {
        selectedLabels: [mockRegularLabel, mockScopedLabel],
        allowLabelRemove: true,
        labelsFilterBasePath: '/gitlab-org/my-project/issues',
        labelsFilterParam: 'label_name',
        ...props,
      },
      provide: {
        allowScopedLabels: true,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there are no labels', () => {
    beforeEach(() => {
      createComponent({
        selectedLabels: [],
      });
    });

    it('does not apply `gl-mt-4` class to the wrapping container', () => {
      expect(findWrapper().classes()).not.toContain('gl-mt-4');
    });

    it('does not render any labels', () => {
      expect(findAllLabels().length).toBe(0);
    });
  });

  describe('when there are labels', () => {
    beforeEach(() => {
      createComponent();
    });

    it('applies `gl-mt-4` class to the wrapping container', () => {
      expect(findWrapper().classes()).toContain('gl-mt-4');
    });

    it('renders a list of two labels', () => {
      expect(findAllLabels().length).toBe(2);
    });

    it('passes correct props to the regular label', () => {
      expect(findRegularLabel().props('target')).toBe(
        '/gitlab-org/my-project/issues?label_name[]=Foo%20Label',
      );
      expect(findRegularLabel().props('scoped')).toBe(false);
    });

    it('passes correct props to the scoped label', () => {
      expect(findScopedLabel().props('target')).toBe(
        '/gitlab-org/my-project/issues?label_name[]=Foo%3A%3ABar',
      );
      expect(findScopedLabel().props('scoped')).toBe(true);
    });

    it('emits `onLabelRemove` event with the correct ID', () => {
      findRegularLabel().vm.$emit('close');
      expect(wrapper.emitted('onLabelRemove')).toStrictEqual([[mockRegularLabel.id]]);
    });
  });
});
