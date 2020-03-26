# frozen_string_literal: true

module VulnerabilitiesHelper
  def vulnerability_data(vulnerability, pipeline)
    return unless vulnerability

    {
      vulnerability_json: vulnerability.to_json,
      project_fingerprint: vulnerability.finding.project_fingerprint,
      create_issue_url: create_vulnerability_feedback_issue_path(vulnerability.finding.project),
      pipeline_json: vulnerability_pipeline_data(pipeline).to_json,
      finding: Vulnerabilities::OccurrenceSerializer.new({}).represent(@vulnerability.finding).to_json,
      has_mr: !!@vulnerability.finding.merge_request_feedback.try(:merge_request_iid),
      vulnerability_feedback_help_path: help_page_path("user/application_security/index", anchor: "interacting-with-the-vulnerabilities"),
      finding_json: vulnerability_finding_data(vulnerability.finding).to_json
    }
  end

  def vulnerability_pipeline_data(pipeline)
    return unless pipeline

    {
      id: pipeline.id,
      created_at: pipeline.created_at.iso8601,
      url: pipeline_path(pipeline)
    }
  end

  def vulnerability_finding_data(finding, current_user: nil)
    occurrence = Vulnerabilities::OccurrenceSerializer.new(current_user: current_user).represent(finding)
    remediation = occurrence[:remediations]&.first

    {
      description: occurrence[:description],
      identifiers: occurrence[:identifiers],
      links: occurrence[:links],
      location: occurrence[:location],
      name: occurrence[:name],
      solution: remediation ? remediation['summary'] : occurrence[:solution]
    }
  end
end
