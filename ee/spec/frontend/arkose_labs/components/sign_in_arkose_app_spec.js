import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SignInArkoseApp from 'ee/arkose_labs/components/sign_in_arkose_app.vue';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { initArkoseLabsScript } from 'ee/arkose_labs/init_arkose_labs_script';

// ArkoseLabs enforcement mocks
jest.mock('ee/arkose_labs/init_arkose_labs_script');
let onShown;
let onCompleted;
let onError;
initArkoseLabsScript.mockImplementation(() => ({
  setConfig: ({ onShown: shownHandler, onCompleted: completedHandler, onError: errorHandler }) => {
    onShown = shownHandler;
    onCompleted = completedHandler;
    onError = errorHandler;
  },
}));

const MOCK_USERNAME = 'cassiopeia';

describe('SignInArkoseApp', () => {
  let wrapper;
  let axiosMock;

  // Finders
  const makeTestIdSelector = (testId) => `[data-testid="${testId}"]`;
  const findByTestId = (testId) => document.querySelector(makeTestIdSelector(testId));
  const findSignInForm = () => findByTestId('sign-in-form');
  const findUsernameInput = () => findByTestId('username-field');
  const findSignInButton = () => findByTestId('sign-in-button');
  const findArkoseLabsErrorMessage = () => wrapper.findByTestId('arkose-labs-error-message');
  const findArkoseLabsVerificationTokenInput = () =>
    wrapper.find('input[name="arkose_labs_token"]');

  // Helpers
  const createForm = (username = '') => {
    loadFixtures('sessions/new.html');
    findUsernameInput().value = username;
  };
  const initArkoseLabs = (username) => {
    createForm(username);
    wrapper = mountExtended(SignInArkoseApp, {
      propsData: {
        publicKey: 'arkose-labs-public-api-key',
        formSelector: makeTestIdSelector('sign-in-form'),
        usernameSelector: makeTestIdSelector('username-field'),
        submitSelector: makeTestIdSelector('sign-in-button'),
      },
    });
  };
  const setUsername = (username) => {
    const input = findUsernameInput();
    input.focus();
    input.value = username;
    input.blur();
  };
  const submitForm = () => {
    findSignInForm().dispatchEvent(new Event('submit'));
  };

  // Assertions
  const itInitializesArkoseLabs = () => {
    it("includes ArkoseLabs' script", () => {
      expect(initArkoseLabsScript).toHaveBeenCalled();
    });

    it('creates a hidden input for the verification token', () => {
      const input = findArkoseLabsVerificationTokenInput();

      expect(input.exists()).toBe(true);
      expect(input.element.value).toBe('');
    });
  };
  const expectHiddenArkoseLabsError = () => {
    expect(findArkoseLabsErrorMessage().exists()).toBe(false);
  };
  const expectArkoseLabsInitError = () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.MSG_ARKOSE_FAILURE_BODY);
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('when the username field is pre-filled', () => {
    it("does not include ArkoseLabs' script initially", () => {
      expect(initArkoseLabsScript).not.toHaveBeenCalled();
    });

    it('puts the sign-in button in the loading state', async () => {
      initArkoseLabs(MOCK_USERNAME);
      await nextTick();
      const signInButton = findSignInButton();

      expect(signInButton.innerText).toMatchInterpolatedText('Loading');
      expect(signInButton.disabled).toBe(true);
    });

    it('triggers a request to the captcha_check API', async () => {
      initArkoseLabs(MOCK_USERNAME);

      expect(axiosMock.history.get).toHaveLength(0);

      await waitForPromises();

      expect(axiosMock.history.get).toHaveLength(1);
      expect(axiosMock.history.get[0].url).toMatch(`/users/${MOCK_USERNAME}/captcha_check`);
    });

    describe('if the challenge is not needed', () => {
      beforeEach(async () => {
        axiosMock.onGet().reply(200, { result: false });
        initArkoseLabs(MOCK_USERNAME);
        await waitForPromises();
      });

      it('resets the loading button', () => {
        const signInButton = findSignInButton();

        expect(signInButton.innerText).toMatchInterpolatedText('Sign in');
        expect(signInButton.disabled).toBe(false);
      });

      it('does not show ArkoseLabs error when submitting the form', async () => {
        submitForm();
        await nextTick();

        expect(findArkoseLabsErrorMessage().exists()).toBe(false);
      });

      describe('if the challenge becomes needed', () => {
        beforeEach(async () => {
          axiosMock.onGet().reply(200, { result: true });
          setUsername(`malicious-${MOCK_USERNAME}`);
          await waitForPromises();
        });

        itInitializesArkoseLabs();
      });
    });

    describe('if the challenge is needed', () => {
      beforeEach(async () => {
        axiosMock.onGet().reply(200, { result: true });
        initArkoseLabs(MOCK_USERNAME);
        await waitForPromises();
      });

      itInitializesArkoseLabs();

      it('shows ArkoseLabs error when submitting the form', async () => {
        submitForm();
        await nextTick();

        expect(findArkoseLabsErrorMessage().exists()).toBe(true);
        expect(wrapper.text()).toContain(wrapper.vm.$options.MSG_ARKOSE_NEEDED);
      });

      it('un-hides the challenge container once the iframe has been shown', async () => {
        expect(wrapper.isVisible()).toBe(false);

        onShown();
        await nextTick();

        expect(wrapper.isVisible()).toBe(true);
      });

      it('shows an error alert if the challenge fails to load', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});

        expect(wrapper.text()).not.toContain(wrapper.vm.$options.MSG_ARKOSE_FAILURE_BODY);

        const error = new Error();
        onError(error);

        // eslint-disable-next-line no-console
        expect(console.error).toHaveBeenCalledWith('ArkoseLabs initialization error', error);

        await nextTick();

        expectArkoseLabsInitError();
      });

      describe('when ArkoseLabs calls `onCompleted` handler that has been configured', () => {
        const response = { token: 'verification-token' };

        beforeEach(() => {
          submitForm();

          onCompleted(response);
        });

        it('removes ArkoseLabs error', () => {
          expectHiddenArkoseLabsError();
        });

        it('does not show again the error when re-submitting the form', () => {
          submitForm();

          expectHiddenArkoseLabsError();
        });

        it("sets the verification token input's value", () => {
          expect(findArkoseLabsVerificationTokenInput().element.value).toBe(response.token);
        });
      });
    });
  });

  describe('when the username check fails', () => {
    beforeEach(async () => {
      jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    it('with a 404, nothing happens', async () => {
      axiosMock.onGet().reply(404);
      initArkoseLabs(MOCK_USERNAME);
      await waitForPromises();

      expect(initArkoseLabsScript).not.toHaveBeenCalled();
      expectHiddenArkoseLabsError();
    });

    it('with some other HTTP error, the challenge is initialized', async () => {
      axiosMock.onGet().reply(500);
      initArkoseLabs(MOCK_USERNAME);
      await waitForPromises();

      expect(initArkoseLabsScript).toHaveBeenCalled();
      expectHiddenArkoseLabsError();
    });

    it('due to the script inclusion, an error is shown', async () => {
      const error = new Error();
      initArkoseLabsScript.mockImplementation(() => {
        throw new Error();
      });
      axiosMock.onGet().reply(200, { result: true });
      initArkoseLabs(MOCK_USERNAME);
      await waitForPromises();

      expectArkoseLabsInitError();
      // eslint-disable-next-line no-console
      expect(console.error).toHaveBeenCalledWith('ArkoseLabs initialization error', error);
    });
  });
});
