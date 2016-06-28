module KnowItAll
  class Base
    def self.assert(method_name, message)
      @@validations ||= {}
      @@validations[method_name] = message
    end

    def errors
      @@validations.each
        .select { |method_name, _| !self.send(method_name) }
        .map { |_, message| message }
    end

    def authorize?
      errors.empty?
    end
  end
end
