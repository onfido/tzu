module Tzu
  class Step
    String.send(:include, ::Tzu::CoreExtensions::String)
    attr_reader :klass, :param_mutator

    def initialize(klass)
      @klass = klass
    end

    def run(params, prior_results)
      command_params = process(params, prior_results)
      @klass.run(command_params)
    end

    def name
      return @name if @name && @name.is_a?(Symbol)
      @klass.to_s.symbolize
    end

    def receives(&block)
      @param_mutator = block
    end

    def as(name)
      @name = name
    end

    private

    def process(params, prior_results)
      instance_exec(params, prior_results, &@param_mutator)
    end
  end
end
