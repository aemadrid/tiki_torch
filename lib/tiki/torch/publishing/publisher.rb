module Tiki
  module Torch
    module Publishing
      class Publisher

        include Logging
        extend Forwardable

        def publish(topic_name, event)
          log_debug(topic_name, event)
          queue_name, event = build_queue_name(topic_name, event)
          res = write(queue_name, event)
          monitor_publish(topic_name, event.payload, event.properties)
          debug_var(:res, res)
          res
        rescue Exception => e
          log_exception e, section: 'publisher', topic: topic_name
        end

        def to_s
          %{#<T:T:Publisher manager=#{manager} callbacks=#{@callbacks.size}>}
        end

        private

        def log_debug(topic_name, event)
          debug "topic_name : #{topic_name} | payload : (#{event.payload.class.name}) #{event.payload.inspect} | properties : (#{event.properties.class.name}) #{event.properties.inspect}"
        end

        def build_queue_name(name, event)
          properties = event.properties.dup
          channel  = properties.delete(:channel) || Torch.config.channel
          new_name = ''
          prefix   = properties.delete(:prefix) || Torch.config.prefix
          new_name << "#{prefix}-" unless name.start_with? prefix
          new_name << name
          new_name << "-#{channel}" unless name.end_with? channel

          # we don't want to encode the prefix and channel properties, and event is immutable
          new_event = Message.new(event.payload, properties, event.format, event.serialization_strategy)
          [new_name, new_event]
        end

        def monitor_publish(topic_name, payload, properties)
          debug "topic_name:#{topic_name} | payload:#{payload.class.name} | properties:#{properties.class.name}"
        end

        def write(name, event)
          queue = Torch.client.queue name
          debug_var :queue, queue
          raise "Could not obtain queue [#{name}]" unless queue.is_a? AwsQueue

          queue.send_message event.serialize
        end

      end

    end

    extend self

    def publisher
      @publisher ||= manager.publisher
    end

    def publish_message(topic_name, message)
      publisher.publish(topic_name, message)
    end

    def publish(topic_name, payload = {}, properties = {}, format = Torch.config.transcoder_code)
      message = Publishing::Message.new(payload, properties, format, Torch.config.serialization_strategy)
      publish_message(topic_name, message)
    end

  end
end
