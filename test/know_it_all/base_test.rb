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
      it "doesn't fail due to expecting `name_present?` method" do
        class AnotherMockPolicy < KnowItAll::Base
          attr_accessor :title

          assert :title_present?, "Title is missing"

          def title_present?
            title && !title.empty?
          end
        end
        expect { AnotherMockPolicy.new }.wont_raise

        policy = AnotherMockPolicy.new
        expect(policy.errors).must_equal ["Title is missing"]

        policy.title = "Something"
        expect(policy.errors).must_equal []
      end
    end
  end
end
