module SidekiqDelegate
  module Validator

    def validate_delegate!(method_with_args)
      unless method_with_args.is_a?(Method::WithArgs)
        raise SidekiqDelegate::Error::DelegateError, "#{name}##{__method__} delegate must be a Method::WithArgs"
      end

      return if method_with_args.receiver.is_a?(Class)

      raise SidekiqDelegate::Error::DelegateError, "#{name}##{__method__} delegate must be a class method"
    end
    module_function :validate_delegate!

  end
end