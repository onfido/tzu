module Tzu
  module Validation
    def self.included(base)
      base.class_eval do
        # registers validation as a before hook
        before :when_valid
      end
    end

    def when_valid(params)
      validation_result = validate(params)
      invalid!(validation_result.errors) unless validation_result.valid?
      validation_result
    end

    def validate(params)
      return ValidationResult.new(params.valid?, params.errors) if params.respond_to?(:valid?)

      ValidationResult.new(true)
    end

    def invalid!(obj)
      output = [:errors, :messages, :message].reduce(obj) do |result, m|
        result.respond_to?(m) ? result.send(m) : result
      end

      raise Invalid.new(output)
    end

    def fail!(type, data = {})
      raise Failure.new(type, data)
    end
  end
end
