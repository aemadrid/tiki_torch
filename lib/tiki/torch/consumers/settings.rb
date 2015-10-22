module Tiki
  module Torch
    class Consumer
      module Settings

        class Config

          include Virtus.model

          attribute :topic, String
          attribute :topic_prefix, String, default: lambda { |_, _| Torch.config.topic_prefix }, lazy: true
          attribute :channel, String, default: lambda { |_, _| Torch.config.channel }, lazy: true

          attribute :default_delay, Integer, default: lambda { |_, _| Torch.config.default_delay }, lazy: true
          attribute :max_size, Integer, default: lambda { |_, _| Torch.config.max_size }, lazy: true
          attribute :retention_period, Integer, default: lambda { |_, _| Torch.config.retention_period }, lazy: true
          attribute :policy, String, default: lambda { |_, _| Torch.config.policy }, lazy: true
          attribute :receive_delay, Integer, default: lambda { |_, _| Torch.config.receive_delay }, lazy: true
          attribute :visibility_timeout, Integer, default: lambda { |_, _| Torch.config.visibility_timeout }, lazy: true

          attribute :use_dlq, Boolean, default: lambda { |_, _| Torch.config.use_dlq }, lazy: true
          attribute :dlq_postfix, String, default: lambda { |_, _| Torch.config.dlq_postfix }, lazy: true
          attribute :max_attempts, Integer, default: lambda { |_, _| Torch.config.max_attempts }, lazy: true

          attribute :event_pool_size, Integer, default: lambda { |_, _| Torch.config.event_pool_size }, lazy: true
          attribute :transcoder_code, String, default: lambda { |_, _| Torch.config.transcoder_code }, lazy: true
          attribute :events_sleep_times, Hash, default: lambda { |_, _| Torch.config.events_sleep_times }, lazy: true

          attr_reader :consumer

          def initialize(consumer, options = {})
            @consumer = consumer
            super(options)
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
                         :topic, :topic=, :topic_prefix, :topic_prefix=, :channel, :channel=,
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
            prefix = config.topic_prefix || 'prefix'
            "#{prefix}-#{topic}-#{channel}"
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
