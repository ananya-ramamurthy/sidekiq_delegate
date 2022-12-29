module Sidekiq
  class Batch

    # The two methods wrap and await are added to enable blocking of processing
    # while until a batch completes.
    # e.g.
    #
    # Sidekiq::Batch.new.wrap do
    #   # jobs enqueued here will complete before execution proceeds past await
    #   YourJob.perform_async
    # end.await

    def wrap
      jobs do
        yield self
      end
      self
    end

    def await
      status.join
      self
    end

    # on_status_change is added to easily get callbacks for any change in batch status
    # complete, success, or death.

    def on_status_change(call, options)
      on(:complete, call, options)
      on(:success, call, options)
      on(:death, call, options)
    end

  end
end