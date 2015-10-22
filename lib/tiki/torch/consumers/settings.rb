module Tiki
  module Torch
    class Consumer
      module Settings

        class Config

          include Virtus.model

          attribute :topic, String
          attribute :topic_prefix, String, default: lambda { |_, _| Torch.config.topic_prefix }, lazy: true
          attribute :channel, String, default: 'events'

          attribute :create_dlq, Boolean, default: lambda { |_, _| Torch.config.create_dlq }, lazy: true
          attribute :max_dlq, Integer, default: lambda { |_, _| Torch.config.max_dlq }, lazy: true
          attribute :dlq_postfix, String, default: lambda { |_, _| Torch.config.dlq_postfix }, lazy: true

          attribute :visibility_timeout, Integer, default: lambda { |_, _| Torch.config.visibility_timeout }, lazy: true
          attribute :message_retention_period, Integer, default: lambda { |_, _| Torch.config.message_retention_period }, lazy: true

          attribute :max_in_flight, Integer, default: lambda { |_, _| Torch.config.max_in_flight }, lazy: true
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
                         :create_dlq, :create_dlq=, :max_dlq, :max_dlq=, :dlq_postfix, :dlq_postfix=,
                         :visibility_timeout, :visibility_timeout=, :message_retention_period, :message_retention_period=,
                         :max_in_flight, :max_in_flight=, :max_attempts, :max_attempts=,
                         :event_pool_size, :transcoder_code, :events_sleep_times

          def configure
            yield config
          end

          def consumes(topic_name, options = {})
            config.topic = topic_name
            options.each { |k, v| config.send "#{k}=", v }
          end

          def queue_name
            prefix = config.topic_prefix || ::Tiki::Torch.config.topic_prefix || 'prefix'
            "#{prefix}-#{topic}-#{channel}"
          end

          def dead_letter_queue_name
            "#{queue_name}-#{dlq_postfix}"
          end

        end
      end
    end
  end
end
