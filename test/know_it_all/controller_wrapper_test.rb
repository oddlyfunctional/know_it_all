require 'test_helper'

describe KnowItAll::ControllerWrapper do
  it "includes the KnowItAll module" do
    expect(KnowItAll::ControllerWrapper.include?(KnowItAll)).must_equal true
  end

  it "delegates controller_path to the controller" do
    controller = MiniTest::Mock.new
    controller.expect(:controller_path, "mock")

    wrapper = KnowItAll::ControllerWrapper.new(controller)

    expect(wrapper.controller_path).must_equal "mock"
    controller.verify
  end

  it "delegates action_name to the controller" do
    controller = MiniTest::Mock.new
    controller.expect(:action_name, "index")

    wrapper = KnowItAll::ControllerWrapper.new(controller)

    expect(wrapper.action_name).must_equal "index"
    controller.verify
  end

  it "delegates policy to the controller, if defined" do
    controller = MiniTest::Mock.new
    controller.expect(:policy, :policy)

    wrapper = KnowItAll::ControllerWrapper.new(controller)

    expect(wrapper.policy).must_equal :policy
    controller.verify
  end

  it "delegates policy_class to the controller, if defined" do
    controller = MiniTest::Mock.new
    controller.expect(:policy_class, :policy_class)

    wrapper = KnowItAll::ControllerWrapper.new(controller)

    expect(wrapper.policy_class).must_equal :policy_class
    controller.verify
  end

  it "delegates policy_name to the controller, if defined" do
    controller = MiniTest::Mock.new
    controller.expect(:policy_name, :policy_name)

    wrapper = KnowItAll::ControllerWrapper.new(controller)

    expect(wrapper.policy_name).must_equal :policy_name
    controller.verify
  end

  it "uses the KnowItAll#policy_name if not defined in the controller" do
    controller = MiniTest::Mock.new
    controller.expect(:controller_path, "mock")
    controller.expect(:action_name, "index")

    wrapper = KnowItAll::ControllerWrapper.new(controller)

    expect(wrapper.policy_name).must_equal "MockPolicy::Index"
    controller.verify
  end
end
