require 'test_helper'

describe KnowItAll::Base do
  describe ".assert" do
    class MockPolicy < KnowItAll::Base
      attr_accessor :name

      assert :name_present?, "Name is missing"

      def name_present?
        name && !name.empty?
      end
    end

    it "adds the message to the errors set when failed" do
      expect(MockPolicy.new.errors).must_equal ["Name is missing"]
    end

    it "doesn't add any message if the validation succeeded" do
      policy = MockPolicy.new
      policy.name = "Something"
      expect(policy.errors).must_equal []
    end

    describe "more than one class extending KnowItAll::Base" do
      class AnotherMockPolicy < KnowItAll::Base
        attr_accessor :title

        assert :title_present?, "Title is missing"

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

        assert :title_present?, "Title is missing"

        def title_present?
          title && !title.empty?
        end
      end

      it "validates both parent's and child's defined assertions" do
        expect(ChildMockPolicy.new.errors).must_equal ["Name is missing", "Title is missing"]
      end
    end
  end
end
