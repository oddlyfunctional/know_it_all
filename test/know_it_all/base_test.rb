require 'test_helper'

describe KnowItAll::Base do
  describe ".validate" do
    class MockPolicy < KnowItAll::Base
      attr_accessor :from_string, :from_proc, :from_i18n

      validate :from_string?, "Message from String"
      validate :from_proc?, -> (policy) { "Message from Proc: #{policy.class}" }
      validate :from_i18n?

      def from_string?
        from_string
      end

      def from_proc?
        from_proc
      end

      def from_i18n?
        from_i18n
      end
    end

    it "adds the message to the errors set when failed" do
      policy = MockPolicy.new
      expect(policy.errors).must_equal ["Message from String", "Message from Proc: MockPolicy", "Message from I18n"]
    end

    it "doesn't add any message if the validation succeeded" do
      policy = MockPolicy.new
      policy.from_string = true
      policy.from_proc = true
      policy.from_i18n = true
      expect(policy.errors).must_equal []
    end

    describe "more than one class extending KnowItAll::Base" do
      class AnotherMockPolicy < KnowItAll::Base
        attr_accessor :title

        validate :title_present?, "Title is missing"

        def title_present?
          title && !title.empty?
        end
      end

      it "doesn't fail due to expecting `name_present?` method" do
        policy = AnotherMockPolicy.new
        expect(policy.errors).must_equal ["Title is missing"]

        policy.title = "Something"
        expect(policy.errors).must_equal []
      end
    end

    describe "inheriting a subclass of KnowItAll::Base" do
      class ChildMockPolicy < MockPolicy
        attr_accessor :title

        validate :title_present?, "Title is missing"

        def title_present?
          title && !title.empty?
        end
      end

      it "validates both parent's and child's defined validations" do
        expect(ChildMockPolicy.new.errors).must_equal ["Message from String", "Message from Proc: ChildMockPolicy", "Message from I18n", "Title is missing"]
      end
    end
  end
end
