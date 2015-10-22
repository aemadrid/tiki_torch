module Tiki
  module Torch
    class Publisher

      include Logging
      extend Forwardable

      def publish(topic_name, payload = {}, properties = {})
        debug "topic_name : #{topic_name} | payload : (#{payload.class.name}) #{payload.inspect} | properties : (#{properties.class.name}) #{properties.inspect}"
        properties = build_properties properties
        queue_name = build_queue_name topic_name
        code       = build_code properties
        encoded    = encode payload, properties, code
        res = write queue_name, encoded
        debug_var :res, res
        res
      end

      private

      def build_properties(properties)
        Torch.config.default_message_properties.dup.
          merge(message_id: SecureRandom.hex).
          merge(properties)
      end

      def build_queue_name(name, channel = Torch.config.channel)
        new_name = ''
        prefix = Torch.config.topic_prefix
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

      def to_s
        %{#<T:T:Publisher manager=#{manager}>}
      end

      alias :inspect :to_s

    end

    extend self

    def publish(topic_name, payload = {}, properties = {})
      manager.publisher.publish topic_name, payload, properties
    end

  end
end