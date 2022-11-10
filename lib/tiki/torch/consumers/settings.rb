module Tiki
  module Torch
    class Consumer
      module Settings

        class Config

          attr_accessor :topic
          attr_writer :prefix, :channel
          attr_writer :default_delay, :max_size, :retention_period, :policy, :receive_delay, :visibility_timeout
          attr_writer :use_dlq, :dlq_postfix, :max_attempts
          attr_writer :event_pool_size, :transcoder_code, :serialization_strategy, :events_sleep_times

          attr_reader :consumer

          def initialize(consumer, options = {})
            @consumer = consumer
          end

          def prefix
            @prefix || Torch.config.prefix
          end

          def channel
            @channel || Torch.config.channel
          end

          def default_delay
            @default_delay || Torch.config.default_delay
          end

          def max_size
            @max_size || Torch.config.max_size
          end

          def retention_period
            @retention_period || Torch.config.retention_period
          end

          def policy
            @policy || Torch.config.policy
          end

          def receive_delay
            @receive_delay || Torch.config.receive_delay
          end

          def visibility_timeout
            @visibility_timeout || Torch.config.visibility_timeout
          end

          def use_dlq
            @use_dlq || Torch.config.use_dlq
          end

          def dlq_postfix
            @dlq_postfix || Torch.config.dlq_postfix
          end

          def max_attempts
            @max_attempts || Torch.config.max_attempts
          end

          def event_pool_size
            @event_pool_size || Torch.config.event_pool_size
          end

          def transcoder_code
            @transcoder_code || Torch.config.transcoder_code
          end

          def permitted_classes_for_YAML
            @permitted_classes_for_YAML || Torch.config.permitted_classes_for_YAML
          end

          def serialization_strategy
            @serialization_strategy || Torch.config.serialization_strategy
          end

          def events_sleep_times
            @events_sleep_times || Torch.config.events_sleep_times
          end

          def to_s
            %{#<T:T:C:Config topic=#{topic.inspect} channel=#{channel.inspect} visibility_timeout=#{visibility_timeout} event_pool_size=#{event_pool_size}>}
          end

          alias :inspect :to_s

        end

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          extend Forwardable

          def config
            @config ||= Config.new self
          end

          def_delegators :config,
                         :topic, :topic=, :prefix, :prefix=, :channel, :channel=,
                         :default_delay, :default_delay=, :max_size, :max_size=, :retention_period, :retention_period=,
                         :policy, :policy=, :receive_delay, :receive_delay=, :visibility_timeout, :visibility_timeout=,
                         :use_dlq, :use_dlq=, :dlq_postfix, :dlq_postfix=, :max_attempts, :max_attempts=,
                         :event_pool_size, :event_pool_size=, :transcoder_code, :transcoder_code=,
                         :events_sleep_times, :events_sleep_times=

          def configure
            yield config
          end

          def consumes(topic_name, options = {})
            config.topic = topic_name
            options.each { |k, v| config.send "#{k}=", v }
          end

          def queue_name
            prefix = config.prefix || 'prefix'
            "#{prefix}-#{topic}-#{channel}"
          end

          def monitor_name
            Utils.simplified_name queue_name
          end

          def dead_letter_queue_name
            return nil unless use_dlq

            "#{queue_name}-#{dlq_postfix}"
          end

        end
      end
    end
  end
end
