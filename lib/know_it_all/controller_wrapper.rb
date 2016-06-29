module KnowItAll
  class ControllerWrapper
    include KnowItAll

    def initialize(controller)
      self.controller = controller
    end

    def controller_path
      controller.controller_path
    end

    def action_name
      controller.action_name
    end

    def policy(*args)
      controller.respond_to?(:policy) && controller.policy(*args) || super
    end

    def policy_class(*args)
      controller.respond_to?(:policy_class) && controller.policy_class(*args) || super
    end

    def policy_name(*args)
      controller.respond_to?(:policy_name) && controller.policy_name(*args) || super
    end

    private

      attr_accessor :controller
  end
end
