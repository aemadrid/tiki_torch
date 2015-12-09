module Tiki
  module Torch
    class Publisher

      include Logging
      extend Forwardable

      def publish(topic_name, payload = {}, properties = {})
        debug "topic_name : #{topic_name} | payload : (#{payload.class.name}) #{payload.inspect} | properties : (#{properties.class.name}) #{properties.inspect}"
        properties = build_properties properties
        queue_name = build_queue_name topic_name, properties
        code       = build_code properties
        encoded    = encode payload, properties, code
        res        = write queue_name, encoded
        monitor_publish topic_name, payload, properties
        debug_var :res, res
        res
      rescue Exception => e
        error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
      end

      def to_s
        %{#<T:T:Publisher manager=#{manager} callbacks=#{@callbacks.size}>}
      end

      alias :inspect :to_s

      private

      def build_properties(properties)
        Torch.config.default_message_properties.dup.
          merge(message_id: SecureRandom.hex, published_at: Time.now).
          merge(properties)
      end

      def build_queue_name(name, properties)
        channel  = properties.delete(:channel) || Torch.config.channel
        new_name = ''
        prefix   = properties.delete(:prefix) || Torch.config.prefix
        new_name << "#{prefix}-" unless name.start_with? prefix
        new_name << name
        new_name << "-#{channel}" unless name.end_with? channel
        new_name
      end

      def build_code(properties)
        properties.delete(:transcoder_code) || Torch.config.transcoder_code
      end

      def encode(payload, properties, code)
        Torch::Transcoder.encode payload, properties, code
      end

      def write(name, encoded)
        queue = Torch.client.queue name
        debug_var :queue, queue
        raise "Could not obtain queue [#{name}]" unless queue.is_a? AwsQueue

        queue.send_message encoded
      end

      def monitor_publish(topic_name, payload, properties)
        debug "topic_name:#{topic_name} | payload:#{payload.class.name} | properties:#{properties.class.name}"
      end

    end

    extend self

    def publisher
      manager.publisher
    end

    def publish(topic_name, payload = {}, properties = {})
      publisher.publish topic_name, payload, properties
    end

  end
end