module Tzu
  class ValidationResult
    attr_reader :errors, :valid

    def initialize(valid, errors = [])
      @valid, @errors = valid, errors
    end

    def valid?
      @valid
    end
  end
end