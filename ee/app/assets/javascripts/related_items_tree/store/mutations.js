import Vue from 'vue';

import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_CONFIG](
    state,
    { epicsEndpoint, issuesEndpoint, autoCompleteEpics, autoCompleteIssues },
  ) {
    state.epicsEndpoint = epicsEndpoint;
    state.issuesEndpoint = issuesEndpoint;
    state.autoCompleteEpics = autoCompleteEpics;
    state.autoCompleteIssues = autoCompleteIssues;
  },

  [types.SET_INITIAL_PARENT_ITEM](state, data) {
    state.parentItem = { ...data };
    state.childrenFlags[state.parentItem.reference] = {};
  },

  [types.SET_CHILDREN_COUNT](state, { epicsCount, issuesCount }) {
    state.epicsCount = epicsCount;
    state.issuesCount = issuesCount;
  },

  [types.SET_ITEM_CHILDREN](state, { parentItem, children }) {
    Vue.set(state.children, parentItem.reference, children);
  },

  [types.SET_ITEM_CHILDREN_FLAGS](state, { children }) {
    children.forEach(item => {
      Vue.set(state.childrenFlags, item.reference, {
        itemExpanded: false,
        itemChildrenFetchInProgress: false,
        itemRemoveInProgress: false,
        itemHasChildren: item.hasChildren || item.hasIssues,
      });
    });
  },

  [types.REQUEST_ITEMS](state, { parentItem, isSubItem }) {
    if (isSubItem) {
      state.childrenFlags[parentItem.reference].itemChildrenFetchInProgress = true;
    } else {
      state.itemsFetchInProgress = true;
    }
  },
  [types.RECEIVE_ITEMS_SUCCESS](state, { parentItem, children, isSubItem }) {
    if (isSubItem) {
      state.childrenFlags[parentItem.reference].itemChildrenFetchInProgress = false;
    } else {
      state.itemsFetchInProgress = false;
      state.itemsFetchResultEmpty = children.length === 0;
    }
  },
  [types.RECEIVE_ITEMS_FAILURE](state, { parentItem, isSubItem }) {
    if (isSubItem) {
      state.childrenFlags[parentItem.reference].itemChildrenFetchInProgress = false;
    } else {
      state.itemsFetchInProgress = false;
    }
  },

  [types.EXPAND_ITEM](state, { parentItem }) {
    state.childrenFlags[parentItem.reference].itemExpanded = true;
  },
  [types.COLLAPSE_ITEM](state, { parentItem }) {
    state.childrenFlags[parentItem.reference].itemExpanded = false;
  },

  [types.SET_REMOVE_ITEM_MODAL_PROPS](state, { parentItem, item }) {
    state.removeItemModalProps = {
      parentItem,
      item,
    };
  },

  [types.REQUEST_REMOVE_ITEM](state, { item }) {
    state.childrenFlags[item.reference].itemRemoveInProgress = true;
  },
  [types.RECEIVE_REMOVE_ITEM_SUCCESS](state, { parentItem, item }) {
    state.childrenFlags[item.reference].itemRemoveInProgress = false;

    // Remove the children from array
    const targetChildren = state.children[parentItem.reference];
    targetChildren.splice(targetChildren.indexOf(item), 1);

    // Update flag for parentItem so that expand/collapse
    // button visibility is refreshed correctly.
    state.childrenFlags[parentItem.reference].itemHasChildren = Boolean(targetChildren.length);

    // In case item removed belonged to main epic
    // we also set results empty.
    if (
      state.children[state.parentItem.reference] &&
      !state.children[state.parentItem.reference].length
    ) {
      state.itemsFetchResultEmpty = true;
    }
  },
  [types.RECEIVE_REMOVE_ITEM_FAILURE](state, { item }) {
    state.childrenFlags[item.reference].itemRemoveInProgress = false;
  },

  [types.TOGGLE_ADD_ITEM_FORM](state, { actionType, toggleState }) {
    state.actionType = actionType;
    state.showAddItemForm = toggleState;
    state.showCreateItemForm = false;
  },

  [types.TOGGLE_CREATE_ITEM_FORM](state, { actionType, toggleState }) {
    state.actionType = actionType;
    state.showCreateItemForm = toggleState;
    state.showAddItemForm = false;
  },

  [types.SET_PENDING_REFERENCES](state, references) {
    state.pendingReferences = references;
  },

  [types.ADD_PENDING_REFERENCES](state, references) {
    state.pendingReferences.push(...references);
  },

  [types.REMOVE_PENDING_REFERENCE](state, indexToRemove) {
    state.pendingReferences = state.pendingReferences.filter(
      (ref, index) => index !== indexToRemove,
    );
  },

  [types.SET_ITEM_INPUT_VALUE](state, itemInputValue) {
    state.itemInputValue = itemInputValue;
  },

  [types.REQUEST_ADD_ITEM](state) {
    state.itemAddInProgress = true;
  },
  [types.RECEIVE_ADD_ITEM_SUCCESS](state, { insertAt, items }) {
    state.children[state.parentItem.reference].splice(insertAt, 0, ...items);
    state.itemAddInProgress = false;
    state.itemsFetchResultEmpty = false;
  },
  [types.RECEIVE_ADD_ITEM_FAILURE](state) {
    state.itemAddInProgress = false;
  },

  [types.REQUEST_CREATE_ITEM](state) {
    state.itemCreateInProgress = true;
  },
  [types.RECEIVE_CREATE_ITEM_SUCCESS](state, { insertAt, item }) {
    state.children[state.parentItem.reference].splice(insertAt, 0, item);
    state.itemCreateInProgress = false;
    state.itemsFetchResultEmpty = false;
  },
  [types.RECEIVE_CREATE_ITEM_FAILURE](state) {
    state.itemCreateInProgress = false;
  },
};
