require 'tzu/run_methods'
require 'tzu/failure'
require 'tzu/hooks'
require 'tzu/invalid'
require 'tzu/match'
require 'tzu/organizer'
require 'tzu/outcome'
require 'tzu/validation'
require 'tzu/validation_result'

module Tzu
  def self.included(base)
    base.class_eval do
      extend RunMethods
      include Hooks
      include Validation
    end
  end

  def run(params)
    run!(request_object(params))
  rescue Failure => f
    Outcome.new(false, f.errors, f.type)
  end

  def run!(params)
    with_hooks(params) do |p|
      outcome = call(p)
      outcome.is_a?(Tzu::Outcome) ? outcome : Outcome.new(true, outcome)
    end
  rescue
    rollback! if self.respond_to?(:rollback!)
    raise
  end

  def command_name
    self.class.command_name
  end

  private

  def request_object(params)
    request_klass = self.class.request_object
    return request_klass.new(params) if request_klass
    params
  end
end
