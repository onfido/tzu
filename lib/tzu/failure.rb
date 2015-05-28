module Tzu
  class Failure < StandardError
    attr_reader :errors, :type

    def initialize(type = nil, errors = nil)
      @errors, @type = errors, type
    end

  end
end
