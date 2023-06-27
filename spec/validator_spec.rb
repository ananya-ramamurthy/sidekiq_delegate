RSpec.describe SidekiqDelegate::Validator do
  let(:klass_method) { Faker::Lorem.word.to_sym }
  let(:instance_method) { Faker::Lorem.word.to_sym }
  let(:delegate_klass) do
    delegate_klass = Object.const_set(Faker::Lorem.word.capitalize, Class.new)
    delegate_klass.define_singleton_method(klass_method) {}
    delegate_klass.define_method(instance_method) {}
    delegate_klass
  end
  let(:delegate) { delegate_klass.method(klass_method).with_args }

  it "should be able to use it's class methods as valid sidekiq delegates when transformed with '.with_args'" do
    validation = begin
      subject.validate_delegate!(delegate)
    rescue => e
      e
    end

    expect(validation).not_to be_an_instance_of(SidekiqDelegate::Error::DelegateError)
  end

  it "should not be able to use it's class methods as sidekiq delegates untransformed with '.with_args'" do
    validation = begin
      subject.validate_delegate!(
        delegate_klass.method(klass_method)
      )
    rescue => e
      e
    end

    expect(validation).to be_an_instance_of(SidekiqDelegate::Error::DelegateError)
  end

  it "should not be able to use it's instance methods as sidekiq delegates" do
    validation_1 = begin
      subject.validate_delegate!(
        delegate_klass.new.method(instance_method)
      )
    rescue => e
      e
    end

    validation_2 = begin
      subject.validate_delegate!(
        delegate_klass.new.method(instance_method).with_args
      )
    rescue => e
      e
    end

    expect(validation_1).to be_an_instance_of(SidekiqDelegate::Error::DelegateError)
    expect(validation_2).to be_an_instance_of(SidekiqDelegate::Error::DelegateError)
  end

end