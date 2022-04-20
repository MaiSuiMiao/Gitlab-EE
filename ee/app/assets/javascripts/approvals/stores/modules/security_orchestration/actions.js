import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import scanResultPoliciesQuery from 'ee/threat_monitoring/graphql/queries/scan_result_policies.query.graphql';
import { gqClient } from 'ee/threat_monitoring/utils';
import { fromYaml } from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/lib/from_yaml';
import * as types from './mutation_types';

export const fetchScanResultPolicies = ({ commit }, projectPath) => {
  gqClient
    .query({
      query: scanResultPoliciesQuery,
      variables: { fullPath: projectPath },
    })
    .then(({ data }) => {
      const policies = data.project?.scanResultPolicies?.nodes || [];
      const parsedPolicies = policies
        .map((rawPolicy) => {
          try {
            return { ...fromYaml(rawPolicy.yaml), isSelected: false };
          } catch (e) {
            return null;
          }
        })
        .filter((policy) => policy);
      commit(types.SET_SCAN_RESULT_POLICIES, parsedPolicies);
    })
    .catch((error) => {
      commit(types.SCAN_RESULT_POLICIES_FAILED, error);
      createFlash({
        message: s__(
          'SecurityOrchestration|An error occurred while fetching the scan result policies.',
        ),
      });
      Sentry.captureException(error);
    });
};
