module Tzu
  class Invalid < Failure
    def initialize(errors = nil)
      super(:validation, errors)
    end
  end
end
