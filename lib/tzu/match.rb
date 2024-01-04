module Tzu
  # with thanks to https://github.com/pzol/deterministic
  class Match
    def initialize(outcome, context)
      @outcome, @context, @collection = outcome, context, []
    end

    def result
      matcher = @collection.detect { |m| m.matches?(@outcome.type) }
      raise "No match could be made for #{@outcome}" if matcher.nil?
      @context.instance_exec(@outcome.result, &matcher.block)
    end

    %w[success failure].each do |type|
      define_method type.to_sym do |condition = nil, &result_block|
        push(type, condition, result_block)
      end
    end

    # todo: hash and define_method if more overrides identified
    def invalid(&result_block)
      push("failure", :validation, result_block)
    end

    private

    Matcher = Struct.new(:condition, :block) do
      def matches?(value)
        condition.call(value)
      end
    end

    def push(type, condition, result_block)
      condition_pred = if condition.nil?
        ->(v) { true }
      elsif condition.is_a?(Proc)
        condition
      elsif condition.is_a?(Class)
        ->(v) { condition === @outcome.type }
      else
        ->(v) { @outcome.type == condition }
      end

      matcher_pred = compose_predicates(type_pred[type], condition_pred)
      @collection << Matcher.new(matcher_pred, result_block)
    end

    def compose_predicates(f, g)
      ->(*args) { f[*args] && g[*args] }
    end

    # return a partial function for matching a matcher's type
    def type_pred
      ->(type, x) { @outcome.send(:"#{type}?") }.curry
    end
  end
end
