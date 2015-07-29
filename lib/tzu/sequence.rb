module Tzu
  module Sequence
    def self.included(base)
      base.class_eval do
        include Hooks

        class << self
          attr_reader :steps, :result_block

          def run(*params)
            new(*params).run
          end

          def type
            @type ||= :take_last
          end

          def result(type = nil, &block)
            return @result_block = block if block
            @type = type
          end

          def step(klass, &block)
            @steps = [] unless @steps

            step = Step.new(klass)
            step.instance_eval(&block) if block

            @steps << step
          end
        end

        def initialize(*params)
          @params = params
          @last_outcome = nil
          @prior_results = {}
        end

        def run
          results = sequence_results
          return mutated_result(results) if self.class.result_block
          return @last_outcome if self.class.type == :take_last
          Outcome.new(true, results)
        end

        def sequence_results
          with_hooks(@params) do |params|
            self.class.steps.reduce({}) do |prior_results, step|
              @last_outcome = step.run(*params, prior_results)
              break if last_outcome_is_failure?
              merge_last_outcome_into_prior_results(step, prior_results)
            end
          end
        end

        private

        def last_outcome_is_failure?
          return true if (@last_outcome.respond_to?(:failure?) && @last_outcome.failure?)
          false
        end

        def merge_last_outcome_into_prior_results(step, prior_results)
          result = @last_outcome.respond_to?(:result) ? @last_outcome.result : @last_outcome
          prior_results.merge(step.name => result)
        end

        def mutated_result(results)
          Outcome.new(true, instance_exec(@params, results, &self.class.result_block))
        end
      end
    end
  end
end
