module Tiki
  module Torch
    class Consumer
      module Settings

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          def topic(name = nil)
            if name.nil?
              @topic || name.to_s.underscore
            else
              prefix = config.topic_prefix
              name   = "#{prefix}#{name}" unless name.start_with? prefix
              @topic = name
            end
          end

          def channel(name = nil)
            if name.nil?
              @channel || 'events'
            else
              @channel = name.to_s
            end
          end

          attr_writer :nsqd, :nsqlookupd, :max_in_flight, :discovery_interval, :msg_timeout

          def nsqd
            @nsqd || config.nsqd
          end

          def nsqlookupd
            @nsqlookupd || config.nsqlookupd
          end

          def max_in_flight
            @max_in_flight || config.max_in_flight
          end

          def discovery_interval
            @discovery_interval || config.discovery_interval
          end

          def msg_timeout
            @msg_timeout || config.msg_timeout
          end

          private

          def config
            Tiki::Torch.config
          end

        end
      end
    end
  end
end
