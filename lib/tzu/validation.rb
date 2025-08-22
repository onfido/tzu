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
      methods = (rails_6_1_active_model_errors?(obj) ? [] : [:errors]) + [:messages, :message]
      output = methods.reduce(obj) do |result, m|
        result.respond_to?(m) ? result.send(m) : result
      end

      raise Invalid.new(output)
    end

    def fail!(type, data = {})
      raise Failure.new(type, data)
    end

    private

    # Starting with Rails 6.1, the 'ActiveModel::Errors#errors'
    # returns a list of structured 'ActiveModel::Error':
    # https://github.com/rails/rails/pull/32313. To ensure the same
    # outcome as with previous rails versions, we forbid any calls to
    # `ActiveModel::Errors#errors`.
    def rails_6_1_active_model_errors?(obj)
      return false unless defined?(ActiveModel)

      obj.is_a?(ActiveModel::Errors) && obj.respond_to?(:errors)
    end
  end
end
