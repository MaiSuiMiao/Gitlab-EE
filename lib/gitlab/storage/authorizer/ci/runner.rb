# frozen_string_literal: true

module Gitlab
  module Storage
    module Authorizer
      module Ci
        class Runner < ::Gitlab::Storage::Authorizer::Base
          def match?(relative_url)
            api_pattern('jobs/:id/artifacts').match?(relative_url)
          end

          def authorize!(api, relative_url)
            api.not_allowed! unless Gitlab.config.artifacts.enabled
            api.require_gitlab_workhorse!

            params = api_pattern('jobs/:id/artifacts').params(relative_url)

            job = authenticate_job!(api, params, api.env)

            result = ::Ci::JobArtifacts::CreateService.new(job).authorize(artifact_type: api.params[:artifact_type], filesize: api.params[:filesize])

            if result[:status] == :success
              api.content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
              api.status :ok
              result[:headers]
            else
              api.render_api_error!(result[:message], result[:http_status])
            end
          end

          private

          def authenticate_job!(api, params, env)
            job = current_job(params, env)
            api.forbidden! unless job
            api.forbidden! unless job_token_valid?(job, params, env)

            api.forbidden!('Project has been deleted!') if job.project.nil? || job.project.pending_delete?
            api.forbidden!('Job has been erased!') if job.erased?

            unless job.running?
              api.header 'Job-Status', job.status
              api.forbidden!('Job is not running')
            end

            job
          end

          def job_token_valid?(job, params, env)
            token = (params[API::Ci::Helpers::Runner::JOB_TOKEN_PARAM] || env[API::Ci::Helpers::Runner::JOB_TOKEN_HEADER]).to_s
            token && job.valid_token?(token)
          end

          def current_job(params, env)
            id = params['id']

            if id
              ::Ci::Build
                .sticking
                .stick_or_unstick_request(env, :build, id)
            end

            ::Ci::Build.find_by_id(id)
          end
        end
      end
    end
  end
end
