import Api from '~/api';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import getInitialState from '~/ci_variable_list/store/state';
import * as actions from '~/ci_variable_list/store/actions';
import * as types from '~/ci_variable_list/store/mutation_types';
import mockData from '../services/mock_data';
import { prepareDataForDisplay, prepareEnvironments } from '~/ci_variable_list/store/utils';

jest.mock('~/api.js');

describe('CI variable list store actions', () => {
  let mock;
  let state;
  const mockVariable = {
    environment_scope: '*',
    id: 63,
    key: 'test_var',
    masked: false,
    protected: false,
    value: 'test_val',
    variable_type: 'env_var',
    _destory: true,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = getInitialState();
    state.endpoint = '/variables';
  });

  afterEach(() => {
    mock.restore();
  });

  describe('toggleValues', () => {
    const valuesHidden = false;
    it('commits TOGGLE_VALUES mutation', () => {
      testAction(actions.toggleValues, valuesHidden, {}, [
        {
          type: types.TOGGLE_VALUES,
          payload: valuesHidden,
        },
      ]);
    });
  });

  describe('clearModal', () => {
    it('commits CLEAR_MODAL mutation', () => {
      testAction(actions.clearModal, {}, {}, [
        {
          type: types.CLEAR_MODAL,
        },
      ]);
    });
  });

  describe('resetEditing', () => {
    it('commits RESET_EDITING mutation', () => {
      testAction(
        actions.resetEditing,
        {},
        {},
        [
          {
            type: types.RESET_EDITING,
          },
        ],
        [{ type: 'fetchVariables' }],
      );
    });
  });

  describe('deleteVariable', () => {
    it('dispatch correct actions on successful deleted variable', done => {
      mock.onPatch(state.endpoint).reply(200);

      testAction(
        actions.deleteVariable,
        mockVariable,
        state,
        [],
        [
          { type: 'requestDeleteVariable' },
          { type: 'receiveDeleteVariableSuccess' },
          { type: 'fetchVariables' },
        ],
        () => {
          done();
        },
      );
    });
  });

  describe('updateVariable', () => {
    it('dispatch correct actions on successful updated variable', done => {
      mock.onPatch(state.endpoint).reply(200);

      testAction(
        actions.updateVariable,
        mockVariable,
        state,
        [],
        [
          { type: 'requestUpdateVariable' },
          { type: 'receiveUpdateVariableSuccess' },
          { type: 'fetchVariables' },
        ],
        () => {
          done();
        },
      );
    });
  });

  describe('addVariable', () => {
    it('dispatch correct actions on successful added variable', done => {
      mock.onPatch(state.endpoint).reply(200);

      testAction(
        actions.addVariable,
        {},
        state,
        [],
        [
          { type: 'requestAddVariable' },
          { type: 'receiveAddVariableSuccess' },
          { type: 'fetchVariables' },
        ],
        () => {
          done();
        },
      );
    });
  });

  describe('fetchVariables', () => {
    it('dispatch correct actions on fetchVariables', done => {
      mock.onGet(state.endpoint).reply(200, { variables: mockData.mockVariables });

      testAction(
        actions.fetchVariables,
        {},
        state,
        [],
        [
          { type: 'requestVariables' },
          {
            type: 'receiveVariablesSuccess',
            payload: prepareDataForDisplay(mockData.mockVariables),
          },
        ],
        () => {
          done();
        },
      );
    });
  });

  describe('fetchEnvironments', () => {
    it('dispatch correct actions on fetchEnvironments', done => {
      Api.environments = jest.fn().mockResolvedValue({ data: mockData.mockEnvironments });

      testAction(
        actions.fetchEnvironments,
        {},
        state,
        [],
        [
          { type: 'requestEnvironments' },
          {
            type: 'receiveEnvironmentsSuccess',
            payload: prepareEnvironments(mockData.mockEnvironments),
          },
        ],
        () => {
          done();
        },
      );
    });
  });
});
