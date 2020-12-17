import { createJobsHash, generateJobNeedsDict } from '~/pipelines/utils';

describe('utils functions', () => {
  const jobName1 = 'build_1';
  const jobName2 = 'build_2';
  const jobName3 = 'test_1';
  const jobName4 = 'deploy_1';
  const job1 = { name: jobName1, script: 'echo hello', stage: 'build' };
  const job2 = { name: jobName2, script: 'echo build', stage: 'build' };
  const job3 = {
    name: jobName3,
    script: 'echo test',
    stage: 'test',
    needs: [jobName1, jobName2],
  };
  const job4 = {
    name: jobName4,
    script: 'echo deploy',
    stage: 'deploy',
    needs: [jobName3],
  };
  const userDefinedStage = 'myStage';

  const pipelineGraphData = {
    stages: [
      {
        name: userDefinedStage,
        groups: [],
      },
      {
        name: job4.stage,
        groups: [
          {
            name: jobName4,
            jobs: [{ ...job4 }],
          },
        ],
      },
      {
        name: job1.stage,
        groups: [
          {
            name: jobName1,
            jobs: [{ ...job1 }],
          },
          {
            name: jobName2,
            jobs: [{ ...job2 }],
          },
        ],
      },
      {
        name: job3.stage,
        groups: [
          {
            name: jobName3,
            jobs: [{ ...job3 }],
          },
        ],
      },
    ],
  };

  describe('createJobsHash', () => {
    it('returns an empty object if there are no jobs received as argument', () => {
      expect(createJobsHash([])).toEqual({});
    });

    it('returns a hash with the jobname as key and all its data as value', () => {
      const jobs = {
        [jobName1]: job1,
        [jobName2]: job2,
        [jobName3]: job3,
        [jobName4]: job4,
      };

      expect(createJobsHash(pipelineGraphData.stages)).toEqual(jobs);
    });
  });

  describe('generateJobNeedsDict', () => {
    it('generates an empty object if it receives no jobs', () => {
      expect(generateJobNeedsDict({})).toEqual({});
    });

    it('generates a dict with empty needs if there are no dependencies', () => {
      const smallGraph = {
        [jobName1]: job1,
        [jobName2]: job2,
      };

      expect(generateJobNeedsDict(smallGraph)).toEqual({
        [jobName1]: [],
        [jobName2]: [],
      });
    });

    it('generates a dict where key is the a job and its value is an array of all its needs', () => {
      const jobsWithNeeds = {
        [jobName1]: job1,
        [jobName2]: job2,
        [jobName3]: job3,
        [jobName4]: job4,
      };

      expect(generateJobNeedsDict(jobsWithNeeds)).toEqual({
        [jobName1]: [],
        [jobName2]: [],
        [jobName3]: [jobName1, jobName2],
        [jobName4]: [jobName3, jobName1, jobName2],
      });
    });
  });
});
