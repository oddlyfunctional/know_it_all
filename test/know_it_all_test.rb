require 'test_helper'

describe KnowItAll do
  describe "#authorize?" do
    it "returns true when use case is valid" do
      expect(controller.authorize?(valid_argument)).must_equal true
    end

    it "returns true when use case is invalid" do
      expect(controller.authorize?(invalid_argument)).must_equal false
    end
  end

  describe "#authorize" do
    it "doesn't raise an error when use case is valid" do
      expect { controller.authorize(valid_argument) }.wont_raise
    end

    it "raises an error when use case is invalid" do
      error = expect { controller.authorize(invalid_argument) }.must_raise KnowItAll::NotAuthorized
      expect(error.policy).must_be_kind_of MockPolicy::Index
    end
  end

  describe "#render_not_authorized" do
    it "calls render with a error JSON and :forbidden status" do
      mock = MiniTest::Mock.new
      mock.expect(:render, nil, [
        json: {
          errors: ["Invalid argument: :invalid_argument"]
        },
        status: :forbidden
      ])

      controller.stub(:render, -> (*args) { mock.render(*args) }) do
        controller.render_not_authorized(
          KnowItAll::NotAuthorized.new(controller.policy(invalid_argument))
        )
      end

      assert mock.verify
    end
  end

  describe "#verify_authorized" do
    it "doesn't raise error when #authorize? was called" do
      controller.authorize?(valid_argument)
      expect { controller.verify_authorized }.wont_raise
    end

    it "doesn't raise error when #authorize was called" do
      controller.authorize(valid_argument)
      expect { controller.verify_authorized }.wont_raise
    end

    it "raises error when neither #authorize nor #authorize? were called" do
      expect { controller.verify_authorized }.must_raise KnowItAll::AuthorizationNotPerformedError
    end
  end

  describe "#policy_name" do
    it "finds policies in the root scope" do
      expect(controller.policy_name).must_equal "MockPolicy::Index"
    end

    it "finds policies nested under modules" do
      expect(controller("nested/under/mock").policy_name).must_equal "Nested::Under::MockPolicy::Index"
    end
  end

  def valid_argument
    :valid_argument
  end

  def invalid_argument
    :invalid_argument
  end

  def controller(controller_path = :mock, action_name = :index)
    @controller ||= MockController.new(controller_path, action_name)
  end

  class MockController
    include KnowItAll
    attr_accessor :controller_path, :action_name

    def initialize(controller_path, action_name)
      self.controller_path = controller_path
      self.action_name = action_name
    end

    def render; end
  end

  module MockPolicy
    class Index
      attr_accessor :argument

      def initialize(argument)
        self.argument = argument
      end

      def authorize?
        errors.empty?
      end

      def errors
        errors = []
        errors << "Invalid argument: #{argument.inspect}" if argument != :valid_argument
        errors
      end
    end
  end
end
