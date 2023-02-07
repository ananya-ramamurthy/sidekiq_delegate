# frozen_string_literal: true

require_relative 'extensions/method'

require_relative 'extensions/sidekiq'

require_relative 'sidekiq_delegate/error'
require_relative 'sidekiq_delegate/validator'

require_relative 'sidekiq_delegate/job'

require_relative 'sidekiq_delegate/batch/job'
require_relative 'sidekiq_delegate/batch/contained_job'

require_relative 'sidekiq_delegate/version'

module SidekiqDelegate; end
