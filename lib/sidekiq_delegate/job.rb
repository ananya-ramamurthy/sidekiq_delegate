require 'sidekiq'

module SidekiqDelegate
  module Job

    # This is an opt-in extension to Sidekiq::Worker
    #
    # SidekiqDelegate::Job is so named because all defined work is delegated to
    # a class method belonging to any class.
    #
    # Perform is defined here, and is not expected to be defined in the including job class.
    #
    # It is expected that work will be enqueued via perform_async or perform_bulk.
    # These methods are defined here and guarantee that a well formed, hashified
    # Method::WithArgs will be the only argument passed to your SidekiqDelegate::Job.
    #
    # This further guarantees that the call to the delegate method will be successful,
    # and all business logic, logging, and error handling can be performed in the
    # class containing related business rules rather than in tightly coupled job classes
    # in the worker / job directory.
    #
    # The central goal is to contain business logic within relevant code scopes,
    # rather than dispersing business logic from a given scope across the code base.
    #
    # Relevant job specific details (sidekiq_options, retries, etc.) must still be
    # defined on a Sidekiq::Worker Job class.

    def self.included(base)
      base.include Sidekiq::Worker
      base.include InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
      # A Sidekiq::Worker module that does exactly one thing -- whatever you want!
      # Must be enqueued with a single argument -- a hashified Method::WithArgs.
      # This method will be regenerated in the job and called giving the definition
      # of the work to do to the job enqueueing code.
      #
      def perform(options)
        call_delegate(options)
      end

      private

      def call_delegate(options)
        delegate = delegate_method(options)
        logger.info "#{delegate.inspect} begin"
        delegate.call
      rescue SidekiqDelegate::Error::DelegateError => e
        logger.error "NON-RETRYABLE: #{e.inspect} ( NOTE: This job is misconfigured. Use perform_bulk or perform_async to ensure job is valid during enqueue )"
      ensure
        logger.info "#{delegate.inspect} end"
      end

      def delegate_method(options)
        unless options.is_a?(Hash)
          raise SidekiqDelegate::Error::DelegateError, "enqueued delegate must be a hash"
        end

        Method::WithArgs.from_hash_splat(**options.transform_keys(&:to_sym))
      rescue ArgumentError => e
        raise SidekiqDelegate::Error::DelegateError, e.message
      end

    end

    module ClassMethods
      include Validator

      # Overridden perform_async takes one argument. It must be a Method::WithArgs.
      #
      # example:
      #
      #   YourJob.perform_async(method_with_args, queue: :not_default_queue)
      #
      def perform_async(method_with_args, queue: sidekiq_options['queue'])
        validate_delegate!(method_with_args)
        client_push(
          "class" => self,
          "queue" => queue,
          "args" => [method_with_args.to_h]
        )
      end

      # perform_bulk takes one argument
      # It must be a list. If a block is given, the method performs a single pass over the list, yielding each list entry.
      # This allows the calling method to map a data set to a set of Method::WithArgs, each resulting Method::WithArgs
      # is then validated as each data element is mapped (rather than looping once for mapping, and then looping again for
      # validation). If no block is given, the argument must be a list of Method::WithArgs. In all cases, the list entry
      # must be a valid Method::WithArgs following the conditional block yield.
      #
      # example 1:
      #
      #   YourJob.perform_bulk(source_list) do |source_object|
      #     self.class.method(:process_queued_batch_entry).with_args(
      #       source_object_id: source_object.id
      #     )
      #   end
      #
      # example 2:
      #
      #   method_with_args_list = [
      #     self.class.method(:process_queued_batch_entry).with_args(
      #       source_object_id: source_object.id
      #     )
      #   ]
      #
      #   YourJob.perform_bulk(method_with_args_list, queue: :not_default_queue)
      #
      def perform_bulk(source_list, queue: sidekiq_options['queue'])
        args = source_list.map do |source_object|
          method_with_args = if block_given?
            yield source_object
          else
            source_object
          end

          validate_delegate!(method_with_args)

          [method_with_args.to_h]
        end

        Sidekiq::Client.push_bulk(
          "class" => self,
          "args" => args,
          "queue" => queue
        )
      end

    end

  end
end
