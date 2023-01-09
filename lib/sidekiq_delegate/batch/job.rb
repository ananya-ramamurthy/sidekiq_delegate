module SidekiqDelegate
  module Batch
    module Job

      # This is an opt-in extension to Sidekiq::Worker via SidekiqDelegate::Job
      # Since it is a SidekiqDelegate::Job, perform will only proceed if
      # the work was enqueued with a hashified Method::WithArgs as the only argument.
      #
      # SidekiqDelegate::Batch::Job is so named, because execution will only proceed
      # if the work was enqueued within a batch.jobs block.

      def self.included(base)
        base.include SidekiqDelegate::Job
        base.include InstanceMethods
      end

      module InstanceMethods

        def perform(options)
          unless valid_within_batch?
            logger.warn "batch invalidated (dying quietly)"
            return
          end

          call_delegate(options)
        end

      end

    end
  end
end
