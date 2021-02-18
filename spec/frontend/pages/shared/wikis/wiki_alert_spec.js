import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WikiAlert from '~/pages/shared/wikis/components/wiki_alert.vue';

describe('WikiAlert', () => {
  let wrapper;
  const ERROR = 'There is already a page with the same title in that path.';
  const ERROR_WITH_LINK =
    'Someone edited the page the same time you did. Please check out %{wikiLinkStart}the page%{wikiLinkEnd} and make sure your changes will not unintentionally remove theirs.';
  const PATH = '/test';

  function createWrapper(propsData = {}, stubs = {}) {
    wrapper = shallowMount(WikiAlert, {
      propsData: { wikiPagePath: PATH, ...propsData },
      stubs,
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findGlSprintf = () => wrapper.findComponent(GlSprintf);

  describe('Wiki Alert', () => {
    it('does show an alert when there is an error', () => {
      createWrapper({ error: ERROR });
      expect(findGlAlert().exists()).toBe(true);
      expect(findGlSprintf().exists()).toBe(true);
      expect(findGlSprintf().attributes('message')).toBe(ERROR);
    });

    it('does show the link to the help path', () => {
      createWrapper({ error: ERROR_WITH_LINK }, { GlAlert, GlSprintf });
      expect(findGlLink().attributes('href')).toBe(PATH);
    });
  });
});
