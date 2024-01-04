require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"

module Tzu
  class Step
    DOUBLE_MUTATOR = "You cannot define both receives and receives_many"

    attr_reader :klass, :single_mutator, :splat_mutator

    def initialize(klass)
      @klass = klass
      @invoke_method = :run
    end

    def run(*params, prior_results)
      # Forward parameters as splat if no mutators are defined
      return @klass.send(@invoke_method, *params) if mutator.nil?

      command_params = process(*params, prior_results)

      return @klass.send(@invoke_method, command_params) unless splat?
      @klass.send(@invoke_method, *command_params)
    end

    def name
      return @name if @name&.is_a?(Symbol)

      @klass.to_s.split("::").last.underscore.to_sym
    end

    def receives(&block)
      double_mutator_error if splat?
      @single_mutator = block
    end

    def receives_many(&block)
      double_mutator_error if @single_mutator.present?
      @splat_mutator = block
    end

    def as(name)
      @name = name
    end

    def invoke_with(method)
      @invoke_method = method
    end

    private

    def double_mutator_error
      raise Tzu::InvalidSequence.new(DOUBLE_MUTATOR)
    end

    def mutator
      @single_mutator || @splat_mutator
    end

    def splat?
      @splat_mutator.present?
    end

    def process(*params, prior_results)
      instance_exec(*params, prior_results, &mutator)
    end
  end
end
