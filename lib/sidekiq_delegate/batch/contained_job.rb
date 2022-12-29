module SidekiqDelegate
  module Batch
    module ContainedJob

      # This is an opt-in extension to Sidekiq::Worker via SidekiqDelegate::Batch::Job
      # Since it is a SidekiqDelegate::Batch::Job, execution will only proceed if
      # the work was enqueued within a batch.jobs block.
      #
      # SidekiqDelegate::Batch::ContainedJob is so named because any sidekiq work enqueued
      # during the processing of this job will be added to / contained within this job's parent batch.

      def self.included(base)
        base.include SidekiqDelegate::Batch::Job
        base.include InstanceMethods
      end

      module InstanceMethods

        private

        def call_delegate(options)
          batch.jobs do
            super
          end
        end
      end

    end
  end
end