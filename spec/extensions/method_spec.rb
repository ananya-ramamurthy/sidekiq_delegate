RSpec.describe Method do
  let(:method_name) { Faker::Lorem.word.to_sym }
  let(:return_value){ Faker::Lorem.word }
  let(:mojule) { Object.const_set(Faker::Lorem.word.capitalize, Module.new) }

  subject do
    v = return_value
    mojule.define_singleton_method(method_name) { v }
    mojule.method(method_name)
  end

  it 'can be transformed into a Method::WithArgs by calling ".with_args"' do
    expect(subject).to receive(:args=)
    expect(subject).to receive(:named_args=)
    expect(subject).to receive(:validate_args!)
    expect(subject.with_args).to be_a(Method::WithArgs)
  end

  it 'can be called without arguments' do
    expect(subject.with_args.call).to eq(return_value)
  end

  describe Method::WithArgs do
    context 'is instantiable and usable' do
      context 'when the method has required simple arguments' do
        subject do
          v = return_value
          mojule.define_singleton_method(method_name) { |arg1, arg2, arg3| v }
          mojule.method(method_name)
        end

        it 'should succeed when the right number of arguments are supplied' do
          formed_subject = subject.with_args(1, 2, 3)
          expect(formed_subject).to be_a(Method::WithArgs)
          expect(formed_subject.args).to eq([1, 2, 3])
        end

        it 'should fail when the wrong number of arguments are supplied' do
          expect {subject.with_args }.to raise_error(
            ArgumentError,
            %(
              Method::WithArgs arguments don't match the method signature of the source method:\n\n
              #{subject}\n\n
              (NOTE: unbracketed hash arguments aren't supported)
            ).split.join(' ')
          )
        end

        it 'can be called' do
          expect(subject.with_args(1, 2, 3).call).to eq(return_value)
        end
      end

      context 'when the method has required named arguments' do
        subject do
          v = return_value
          mojule.define_singleton_method(method_name) { |arg1:, arg2:, arg3:| v }
          mojule.method(method_name)
        end

        it 'should succeed when the right number of arguments are supplied' do
          formed_subject = subject.with_args(arg1: 1, arg2: 2, arg3: 3)
          expect(formed_subject).to be_a(Method::WithArgs)
          expect(formed_subject.named_args).to eq(
            arg1: 1,
            arg2: 2,
            arg3: 3
          )
        end

        it 'should fail when the wrong number of arguments are supplied' do
          expect { subject.with_args }.to raise_error(
            ArgumentError,
            %(
              Method::WithArgs arguments don't match the method signature of the source method:\n\n
              #{subject}\n\n
              (NOTE: unbracketed hash arguments aren't supported)
            ).split.join(' ')
          )
        end

        it 'can be called' do
          expect(subject.with_args(arg1: 1, arg2: 2, arg3: 3).call).to eq(return_value)
        end
      end

      context 'when the method has a combination of required simple and named arguments' do
        subject do
          v = return_value
          mojule.define_singleton_method(method_name) { |arg1, arg2, arg3:, arg4:| v }
          mojule.method(method_name)
        end

        it 'should succeed when the right number of arguments are supplied' do
          formed_subject = subject.with_args(1, 2, arg3: 3, arg4: 4)
          expect(formed_subject).to be_a(Method::WithArgs)
          expect(formed_subject.args).to eq([1, 2])
          expect(formed_subject.named_args).to eq(
            arg3: 3,
            arg4: 4
          )
        end

        it 'should fail when the wrong number of arguments are supplied' do
          expect { subject.with_args(1, arg4: 4) }.to raise_error(
            ArgumentError,
            %(
              Method::WithArgs arguments don't match the method signature of the source method:\n\n
              #{subject}\n\n
              (NOTE: unbracketed hash arguments aren't supported)
            ).split.join(' ')
          )
        end

        it 'can be called' do
          expect(subject.with_args(1, 2, arg3: 3, arg4: 4).call).to eq(return_value)
        end
      end

      context 'when the method has splatted args and named args' do
        subject do
          v = return_value
          mojule.define_singleton_method(method_name) { |*args, **nargs| v }
          mojule.method(method_name)
        end

        it 'should succeed when args and named args are included' do
          formed_subject = subject.with_args(1, 2, arg3: 3, arg4: 4)
          expect(formed_subject).to be_a(Method::WithArgs)
          expect(formed_subject.args).to eq([1, 2])
          expect(formed_subject.named_args).to eq(
            arg3: 3,
            arg4: 4
          )
        end

        it 'should succeed when args and named args are not included' do
          formed_subject = subject.with_args
          expect(formed_subject).to be_a(Method::WithArgs)
          expect(formed_subject.args).to eq([])
          expect(formed_subject.named_args).to eq({})
        end
      end
    end

    context 'has useful utility methods' do
      subject do
        mojule.define_singleton_method(method_name) {}
        mojule.method(method_name).with_args
      end

      it "should determine equality based on the full set of parameters and it's source method" do
        expect(subject).to eq(mojule.method(method_name).with_args)
      end

      it 'should be possible to convert to a hash with "to_h" and restore via via "Method::WithArgs.from_hash_splat"' do
        h = subject.to_h
        expect(h).to be_a(Hash)
        expect(Method::WithArgs.from_hash_splat(**h)).to eq(subject)
      end

      it 'should provide facility to see the method from which it was derived' do
        expect(subject.source).to eq(mojule.method(method_name))
      end

      it 'should make args and named args available' do
        expect(subject.args).to be_a(Array)
        expect(subject.named_args).to be_a(Hash)
      end

      it 'should be inspectable' do
        expect(subject.inspect).to be_a(String)
      end

    end
  end

end