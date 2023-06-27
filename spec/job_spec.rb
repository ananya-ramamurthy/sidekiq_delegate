RSpec.describe SidekiqDelegate::Job do
  let(:klass_method) { Faker::Lorem.word.to_sym }
  let(:delegate_klass) do
    klass = Object.const_set(Faker::Lorem.word.capitalize, Class.new)
    klass.define_singleton_method(klass_method) {}
    klass
  end
  let(:delegate) { delegate_klass.method(klass_method).with_args }

  subject(:job_klass) do
    Object.const_set(
      Faker::Lorem.word.capitalize,
      Class.new do
        include SidekiqDelegate::Job
      end
    )
  end

  context 'client_actions' do
    it 'is able to enqueue a single job by calling perform_async' do
      expect(job_klass).to receive(:validate_delegate!).with(delegate)

      expect(job_klass).to receive(:client_push).with(
        'class' => job_klass,
        'queue' => 'default',
        'args' => [delegate.to_h]
      )

      job_klass.perform_async(delegate)
    end

    it 'is able to enqueue a single job by calling perform_async (specifying a different queue)' do
      q = double

      expect(job_klass).to receive(:client_push).with(
        'class' => job_klass,
        'queue' => q,
        'args' => [delegate.to_h]
      )

      job_klass.perform_async(delegate, queue: q)
    end

    it 'is able to enqueue a bulk set of jobs by calling perform_bulk' do
      delegates = []
      count = rand(100) + 10
      count.times do
        delegates << delegate
      end

      hashified_delegates = delegates.map do |mwa|
        [mwa.to_h]
      end

      expect(job_klass).to receive(:validate_delegate!).exactly(count).times
      expect(Sidekiq::Client).to receive(:push_bulk).with(
        'class' => job_klass,
        'queue' => 'default',
        'args' => hashified_delegates
      )

      job_klass.perform_bulk(delegates)
    end

    it 'is able to enqueue a bulk set of jobs by calling perform_bulk (specifying a different queue)' do
      delegates = []
      count = rand(100) + 10
      count.times do
        delegates << delegate
      end

      q = double

      hashified_delegates = delegates.map do |mwa|
        [mwa.to_h]
      end

      expect(Sidekiq::Client).to receive(:push_bulk).with(
        'class' => job_klass,
        'queue' => q,
        'args' => hashified_delegates
      )

      job_klass.perform_bulk(delegates, queue: q)
    end

    context 'having "perform_bulk" called with a block' do
      it 'should yield each element of the argument list to the calling block, \
      and validate and enqueue the modified value returned from the block' do
        transforms = []
        argument_list = (1..rand(100) + 50).to_a.each_with_object([]) do |i, ary|
          h = { i.to_s => false }
          transform = {i.to_s => true}
          transforms << [transform]
          expect(job_klass).to receive(:validate_delegate!).with(transform)
          ary << h
        end

        expect(Sidekiq::Client).to receive(:push_bulk).with(
          'class' => job_klass,
          'queue' => 'default',
          'args' => transforms
        )

        job_klass.perform_bulk(argument_list) do |arg_list_element|
          key = arg_list_element.keys.first
          arg_list_element[key] = true
          arg_list_element
        end
      end

      it 'should ignore nil values returned from the calling block' do
        transforms = []
        argument_list = (1..rand(100) + 50).to_a.each_with_object([]) do |i, ary|
          h = { i.to_s => false }
          transform = {i.to_s => true}

          if i % 2 > 0
            transforms << [transform]
            expect(job_klass).to receive(:validate_delegate!).with(transform)
          end

          ary << h
        end

        expect(Sidekiq::Client).to receive(:push_bulk).with(
          'class' => job_klass,
          'queue' => 'default',
          'args' => transforms
        )

        job_klass.perform_bulk(argument_list) do |arg_list_element|
          key = arg_list_element.keys.first

          if key.to_i % 2 == 0
            nil
          else
            arg_list_element[key] = true
            arg_list_element
          end
        end
      end

      it 'should flatten arrays of values returned from the calling block, validating each entry' do
        transforms = []
        argument_list = (1..rand(100) + 50).to_a.each_with_object([]) do |i, ary|
          h = { i.to_s => false }
          transform_1 = {i.to_s => true}
          transform_2 = {i.to_s => nil}

          transforms << [transform_1]

          if i % 2 > 0
            transforms << [transform_2]
            expect(job_klass).to receive(:validate_delegate!).with(transform_2)
          end

          expect(job_klass).to receive(:validate_delegate!).with(transform_1)

          ary << h
        end

        expect(Sidekiq::Client).to receive(:push_bulk).with(
          'class' => job_klass,
          'queue' => 'default',
          'args' => transforms
        )

        job_klass.perform_bulk(argument_list) do |arg_list_element|
          key = arg_list_element.keys.first
          arg_list_element[key] = true

          if key.to_i % 2 > 0
            [arg_list_element, { key => nil }]
          else
            arg_list_element
          end
        end
      end

    end
  end

  context 'server_actions' do
    subject { job_klass.new }

    it 'should call_delegate when perform is called on an instance' do
      options = Faker::Types::rb_hash
      expect(subject).to receive(:call_delegate).with(options)
      subject.perform(options)
    end

    it 'should log a begin and end message with information about the delegate and "call" it' do
      options = double
      expect(subject).to receive(:delegate_method).with(options).and_return(delegate)
      expect(subject.logger).to receive(:info).with("#{delegate.inspect} begin")
      expect(delegate).to receive(:call)
      expect(subject.logger).to receive(:info).with("#{delegate.inspect} end")

      subject.perform(options)
    end

    context 'validating job options' do
      it 'should die with a no-op and log a descriptive error message if the job options are invalid' do
        options = double
        error = SidekiqDelegate::Error::DelegateError.new
        expect(subject).to receive(:delegate_method).with(options).and_raise(error)
        expect(subject.logger).to receive(:error).with("NON-RETRYABLE: #{error.inspect} \
( NOTE: This job is misconfigured. Use perform_bulk or perform_async to ensure job is valid during enqueue )")
        expect(subject.logger).to receive(:info).with("#{nil.inspect} end")

        subject.perform(options)
      end

      it 'job options should not be valid if they are not a hash' do
        options = double
        expect(subject.logger).to receive(:error)
        subject.perform(options)
      end

      it "job options should not be valid if the options hash doesn't match the delegate structure" do
        options = Faker::Types.rb_hash
        expect(subject.logger).to receive(:error)
        subject.perform(options)
      end

      it "job options should not be valid if the options hash doesn't match the delegate method signature" do
        options = delegate.to_h.merge(args: [double])
        expect(subject.logger).to receive(:error)
        subject.perform(options)
      end
    end
  end

end