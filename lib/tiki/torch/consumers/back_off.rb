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
          debug "Event ##{short_id} will be evaluated to back off ..."
          @back_off = self.class.back_off_strategy.new event, failure, self
          if @back_off.requeue?
            info "Event ##{short_id} will be reran in #{@back_off.time} ms ..."
            event.requeue @back_off.time
          else
            info "Event ##{short_id} will NOT be backed off ..."
            false
          end
        end

      end
    end
  end
end
