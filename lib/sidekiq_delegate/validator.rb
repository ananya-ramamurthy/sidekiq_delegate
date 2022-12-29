module SidekiqDelegate
  module Validator

    def validate_delegate!(method_with_args)
      unless method_with_args.is_a?(Method::WithArgs)
        raise SidekiqDelegate::Error::DelegateError, "#{name}##{__method__} delegate must be a Method::WithArgs"
      end

      validate_delegate_receiver!(method_with_args)
    end
    module_function :validate_delegate!

    def validate_delegate_receiver!(method)
      unless method.is_a?(Method)
        raise SidekiqDelegate::Error::DelegateError, "#{name}##{__method__} delegate must be a method"
      end

      return if method.receiver.is_a?(Class)

      raise SidekiqDelegate::Error::DelegateError, "#{name}##{__method__} delegate must be a class method"
    end
    module_function :validate_delegate_receiver!

  end
end