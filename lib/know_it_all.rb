require "know_it_all/version"
require "know_it_all/base"
require "know_it_all/controller_wrapper"

module KnowItAll
  SUFFIX = "Policy"

  def authorize?(*args)
    authorize(*args).empty?
  end

  def authorize(*args,
                 controller_path: self.controller_path,
                 action_name: self.action_name,
                 policy_name: self.policy_name(
                   controller_path: controller_path,
                   action_name: action_name
                 ),
                 policy_class: self.policy_class(policy_name: policy_name),
                 policy: self.policy(*args, policy_class: policy_class)
                )
    @_authorization_performed = true
    policy.errors
  end

  def authorize!(*args)
    raise NotAuthorized.new(policy(*args)) unless authorize?(*args)
  end

  def policy(*args, policy_class: self.policy_class)
    policy_class.new(*args)
  end

  def policy_class(policy_name: self.policy_name)
    @policy_class ||= policy_name.constantize
  end

  def policy_name(
    controller_path: self.controller_path,
    action_name: self.action_name
  )
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
