RSpec.describe SidekiqDelegate::Batch::Job do

  subject(:job_klass) do
    Object.const_set(
      Faker::Lorem.word.capitalize,
      Class.new do
        include SidekiqDelegate::Batch::Job
      end
    )
  end

  context 'server_actions' do
    subject { job_klass.new }

    it 'should "die quietly" when not valid_with_batch? to prevent frivolous retries' do
      expect(subject).to receive(:valid_within_batch?).and_return(false)
      expect(subject.logger).to receive(:warn).with("batch invalidated (dying quietly)")
      expect(subject).not_to receive(:call_delegate)
      subject.perform(double)
    end

    it 'should call_delegate if it is valid_within_batch?' do
      expect(subject).to receive(:valid_within_batch?).and_return(true)
      expect(subject).to receive(:call_delegate)
      subject.perform(double)
    end
  end

end