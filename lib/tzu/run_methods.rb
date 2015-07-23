module Tzu
  module RunMethods
    attr_reader :request_object

    def run(params, *context, &block)
      result = get_instance(*context).run(params)
      return result.handle(&block) if block
      result
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

    def method_missing(method, *args, &block)
      @request_object = args.first if method == :given
    end
  end
end
