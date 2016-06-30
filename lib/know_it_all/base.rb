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

    def self.assert(method_name, message)
      validations[method_name] = message
    end

    def errors
      self.class.validations.each
        .select { |method_name, _| !self.send(method_name) }
        .map { |_, message| message }
    end
  end
end
