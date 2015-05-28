module Tzu

  # The result of executing a command
  class Outcome
    attr_reader :success, :result, :type

    def initialize(success, result, type = nil)
      @success = success
      @result = result
      @type = type
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def handle(context=nil, &block)
      context ||= block.binding.eval('self')
      match = Match.new(self, context)
      match.instance_eval &block
      match.result
    end
  end
end
