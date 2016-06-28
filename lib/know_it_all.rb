require "know_it_all/version"
require "know_it_all/base"

module KnowItAll
  SUFFIX = "Policy"

  def authorize?(*args)
    @_authorization_performed = true
    policy(*args).authorize?
  end

  def authorize(*args)
    raise NotAuthorized.new(policy(*args)) unless authorize?(*args)
  end

  def policy(*args)
    policy_class.new(*args)
  end

  def policy_class
    @policy_class ||= policy_name.constantize
  end

  def policy_name
    "#{controller_path.to_s.camelize}#{SUFFIX}::#{action_name.to_s.camelize}"
  end

  def render_not_authorized(exception)
    render(
      json: {
        errors: exception.policy.errors
      },
      status: :forbidden
    )
  end

  def verify_authorized
    raise AuthorizationNotPerformedError unless @_authorization_performed
  end

  class NotAuthorized < StandardError
    attr_accessor :policy

    def initialize(policy)
      self.policy = policy
    end
  end

  class AuthorizationNotPerformedError < StandardError; end
end
