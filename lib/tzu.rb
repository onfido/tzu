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
      extend ClassMethods
      include Hooks
    end
  end

  module ClassMethods
    def run(params, *context, &block)
      result = get_instance(*context).run(params)
      if block
        result.handle(&block)
      else
        result
      end
    end

    def run!(params, *context)
      get_instance(*context).run!(params)
    end

    def get_instance(*context)
      method = respond_to?(:build) ? :build : :new
      send(method, *context)
    end

    def command_name(value = nil)
      if value.nil?
        @name ||= name.underscore.to_sym
      else
        @name = (value.presence && value.to_sym)
      end
    end
  end

  def command_name
    self.class.command_name
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

  def fail!(type, data={})
    raise Failure.new(type, data)
  end

  private

  def request_object(params)
    klass = request_class
    return klass.new(params) if klass && !params.is_a?(klass)
    params
  end

  # Get the name of a request class related to calling class
  # ie.   Tzus::MyNameSpace::MyTzu
  # has   Tzus::MyNameSpace::Requests::MyTzu
  def request_class
    namespace =  self.class.name.deconstantize.constantize
    request_object_name = "Requests::#{ self.class.name.demodulize}"
    namespace.qualified_const_get(request_object_name)
  rescue NameError
    false
  end
end
