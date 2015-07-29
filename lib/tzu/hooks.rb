module Tzu

  # Provides hooks for arbitrary pre- and post- processing within a command
  module Hooks
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def before(*hooks, &block)
        hooks << block if block
        hooks.each { |hook| before_hooks.push(hook) }
      end

      def after(*hooks, &block)
        hooks << block if block
        hooks.each { |hook| after_hooks.push(hook) }
      end

      def around(*hooks, &block)
        hooks << block if block
        hooks.each { |hook| around_hooks.push(hook) }
      end

      def before_hooks
        @before_hooks ||= []
      end

      def after_hooks
        @after_hooks ||= []
      end

      def around_hooks
        @around_hooks ||= []
      end
    end

    def with_hooks(*params, &block)
      result = nil
      run_around_hooks do
        run_before_hooks(*params)
        result = yield(*params)
        run_after_hooks(*params)
      end
      result
    end

    private

    def run_around_hooks(&block)
      self.class.around_hooks.reverse.inject(block) do |chain, hook|
        proc { run_hook(hook, chain) }
      end.call
    end

    def run_before_hooks(params)
      run_hooks(self.class.before_hooks, params)
    end

    def run_after_hooks(params)
      run_hooks(self.class.after_hooks, params)
    end

    def run_hooks(hooks, params)
      hooks.each { |hook| run_hook(hook, params) }
    end

    def run_hook(hook, args)
      hook.is_a?(Symbol) ? send(hook, args) : instance_exec(args, &hook)
    end
  end
end
