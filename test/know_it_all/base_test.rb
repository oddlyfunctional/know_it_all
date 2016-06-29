require 'test_helper'

describe KnowItAll::Base do
  describe ".assert" do
    it "adds the message to the errors set when failed" do
      expect(policy.errors).must_equal ["Name is missing"]
    end

    it "doesn't add any message if the validation succeeded" do
      policy.name = "Something"
      expect(policy.errors).must_equal []
    end
  end

  def mock_policy
    Class.new(KnowItAll::Base) do
      attr_accessor :name

      assert :name_present?, "Name is missing"

      def name_present?
        name && !name.empty?
      end
    end
  end

  def policy
    @policy ||= mock_policy.new
  end
end
