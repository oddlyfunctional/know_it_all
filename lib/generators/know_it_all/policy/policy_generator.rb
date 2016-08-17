require 'pry'

module KnowItAll
  module Generators
    class PolicyGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      argument :controller_name, type: :string
      argument :action_names, type: :array

      def create_policy_file
        unless File.exists?("app/policies/#{module_name}.rb")
          template 'module.rb', "app/policies/#{module_name}.rb"
        end

        action_names.each do |action_name|
          @action_name = action_name
          template 'policy.rb', "app/policies/#{module_name}/#{action_name}.rb"
        end
      end

      private

        def module_name
          "#{controller_name}_policies"
        end
    end
  end
end
