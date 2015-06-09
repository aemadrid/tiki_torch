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
    end
  end
end
