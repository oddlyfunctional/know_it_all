module KnowItAll
  class Base
    def self.validations
      @validations ||= {}
    end

    def self.validations=(validations)
      @validations = validations
    end

    def self.inherited(subclass)
      subclass.validations = validations.dup
    end

    # <b>DEPRECATED:</b> Please use <tt>validate</tt> instead.
    def self.assert(*args)
      warn "[DEPRECATION] `assert` is deprecated. Please use `validate` instead."
      validate(*args)
    end

    def self.validate(method_name, message = nil)
      if message.nil? && defined?(I18n)
        class_names = StringHelper.underscore(self.to_s).split("/")
        message = I18n.t(["policies", *class_names, method_name].join("."))
      end
      validations[method_name] = message
    end

    def errors
      self.class.validations.each
        .reject { |method_name, _| self.send(method_name) }
        .map do |_, message|
          if message.respond_to?(:call)
            message.call(self)
          else
            message
          end
        end
    end
  end
end
