module Tzu
  class Failure < StandardError
    attr_reader :type

    def initialize(type = nil, errors = nil)
      @type = type
      @raw_errors = errors
    end

    def errors
      string_error? ? { errors: @raw_errors } : @raw_errors
    end

    def message
      string_error? ? @raw_errors : @raw_errors.to_s
    end

    private

    def string_error?
      @raw_errors.is_a?(String)
    end
  end
end
