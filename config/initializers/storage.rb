# frozen_string_literal: true

Rails.application.configure do
  config.after_initialize do
    ::Gitlab::Storage::Authorizer.registry = ::Gitlab::Storage::Authorizer::Registry.new
  end
end
