# frozen_string_literal: true

require_relative 'extensions/method'

if defined?(Sidekiq::Batch)
  require_relative 'extensions/sidekiq'
end

require_relative 'sidekiq_delegate/error'
require_relative 'sidekiq_delegate/validator'

require_relative 'sidekiq_delegate/job'

if defined?(Sidekiq::Batch)
  require_relative 'sidekiq_delegate/batch/job'
  require_relative 'sidekiq_delegate/batch/contained_job'
end

require_relative 'sidekiq_delegate/version'

module SidekiqDelegate; end
