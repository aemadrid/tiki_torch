module Tiki
  module Torch
    class ConsumerBuilder

      include Logging
      extend Forwardable

      def_delegators :@consumer,
                     :name, :queue_name,
                     :default_delay, :max_size, :retention_period, :policy, :receive_delay, :visibility_timeout,
                     :use_dlq, :dead_letter_queue_name, :max_attempts

      def_delegators :@manager, :client

      def initialize(consumer, manager)
        @consumer = consumer
        @manager  = manager
      end

      def build
        setup_queue
        setup_dlq_queue if use_dlq
        main_queue
      end

      def to_s
        %{#<T:T:ConsumerBuilder consumer=#{name.inspect}>}
      end

      alias :inspect :to_s

      private

      def setup_queue
        ensure_queue_attributes main_queue, queue_options
      end

      def setup_dlq_queue
        ensure_queue_attributes main_queue, dlq_options
      end

      def ensure_queue_attributes(queue, exp_attrs = {})
        found_attributes = queue.attributes
        new_attributes   = exp_attrs.each_with_object({}) do |(k, v), h|
          current = found_attributes[k].to_s
          h[k]    = v.to_s unless current == v.to_s
        end
        unless new_attributes.empty?
          debug "Updating #{queue.name} (#{new_attributes.size}) ..."
          queue.attributes = new_attributes
        else
          debug "No need to update #{queue.name} ..."
        end
      end

      def main_queue
        @main_queue ||= client.queue queue_name
      end

      def dl_queue
        @dl_queue ||= client.queue dead_letter_queue_name
      end

      def queue_options
        options           = {
          'DelaySeconds'                  => default_delay,
          'MaximumMessageSize'            => max_size,
          'MessageRetentionPeriod'        => retention_period,
          'ReceiveMessageWaitTimeSeconds' => receive_delay,
          'VisibilityTimeout'             => visibility_timeout,
        }
        options['Policy'] = policy unless policy.nil?
        options
      end

      def dlq_options
        {
          'RedrivePolicy' => {
            'maxReceiveCount'     => max_attempts,
            'deadLetterTargetArn' => dl_queue.attributes.arn
          }.to_json
        }
      end

    end
  end
end