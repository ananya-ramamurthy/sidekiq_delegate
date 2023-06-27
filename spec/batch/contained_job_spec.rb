RSpec.describe SidekiqDelegate::Batch::ContainedJob do

  subject(:job_klass) do
    Object.const_set(
      Faker::Lorem.word.capitalize,
      Class.new do
        include SidekiqDelegate::Batch::ContainedJob
      end
    )
  end

  context 'server_actions' do
    subject { job_klass.new }

    it 'should call_delegate if it is valid_within_batch?' do
      batch = double
      options = double
      allow(subject).to receive(:valid_within_batch?).and_return(true)

      expect(subject).to receive(:batch).and_return(batch)
      expect(batch).to receive(:jobs).and_yield

      subject.perform(options)
    end
  end

end