module KnowItAll
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def add_module_to_application_controller
        inject_into_file "app/controllers/application_controller.rb",
          after: "class ApplicationController < ActionController::Base\n" do
          "  include KnowItAll\n"
        end
      end

      def create_application_policy_file
        template "application_policy.rb", "app/policies/application_policy.rb"
      end
    end
  end
end
