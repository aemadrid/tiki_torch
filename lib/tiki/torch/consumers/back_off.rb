module Tiki
  module Torch
    class Consumer
      module BackOffStrategies
        class Default

          attr_reader :requeue, :time

          def initialize(event, exception, consumer)
            @requeue = event.attempts < consumer.class.max_attempts
            @time    = consumer.class.back_off_time_unit * event.attempts if @requeue
          end

          alias :requeue? :requeue

        end
      end

      module BackOff

        private

        def back_off_event
          @back_off = self.class.back_off_strategy.new event, failure, self
          if @back_off.requeue?
            event.requeue @back_off.time
            [:backoff, @back_off.time]
          else
            false
          end
        end

      end
    end

    config.back_off_strategy = Consumer::BackOffStrategies::Default
  end
end
