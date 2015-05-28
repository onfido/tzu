require 'ostruct'

module Tzu
  module Organizer
    def self.included(base)
      base.class_eval do
        include Tzu
      end
    end

    Step = Struct.new(:command, :transform)

    def steps
      @steps ||= []
    end

    def add_step(command, &transform)
      steps << Step.new(command, transform)
    end

    def call(params)
      result = call_steps(params)
      self.respond_to?(:parse) ? parse(result) : result
    end

    def call_steps(params)
      result = ::OpenStruct.new
      steps.each do |step|
        call_with = step.transform ? step.transform(params, result) : params
        result[step.command.command_name] = step.command.run!(call_with)
      end
      result
    end
  end
end
