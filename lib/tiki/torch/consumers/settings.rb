module Tiki
  module Torch
    class Consumer
      module Settings

        class Config

          include Virtus.model

          attribute :topic, String
          attribute :channel, String, default: lambda { |config, _| config.default_channel_name }, lazy: true
          attribute :dlq_topic, String

          attribute :nsqlookupd, Array[String], default: lambda { |_, _| ::Tiki::Torch.config.nsqlookupd }, lazy: true
          attribute :nsqd, Array[String], default: lambda { |_, _| ::Tiki::Torch.config.nsqd }, lazy: true

          attribute :max_in_flight, Integer, default: lambda { |_, _| ::Tiki::Torch.config.max_in_flight }, lazy: true
          attribute :discovery_interval, Integer, default: lambda { |_, _| ::Tiki::Torch.config.discovery_interval }, lazy: true
          attribute :msg_timeout, Integer, default: lambda { |_, _| ::Tiki::Torch.config.msg_timeout }, lazy: true

          attribute :back_off_strategy, Integer, default: lambda { |_, _| ::Tiki::Torch.config.back_off_strategy }, lazy: true
          attribute :max_attempts, Integer, default: lambda { |_, _| ::Tiki::Torch.config.max_attempts }, lazy: true
          attribute :back_off_time_unit, Integer, default: lambda { |_, _| ::Tiki::Torch.config.back_off_time_unit }, lazy: true

          attribute :event_pool_size, Integer, default: lambda { |_, _| ::Tiki::Torch.config.event_pool_size }, lazy: true
          attribute :events_sleep_times, Integer, default: lambda { |_, _| ::Tiki::Torch.config.events_sleep_times }, lazy: true

          attr_reader :consumer

          def initialize(consumer, options = {})
            @consumer = consumer
            super(options)
          end

          def default_channel_name
            @consumer.name.underscore.gsub('/', '-')
          end

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
                         :topic, :topic=, :channel, :channel=, :dlq_topic, :dlq_topic=,
                         :nsqlookupd, :nsqd,
                         :max_in_flight, :discovery_interval, :msg_timeout,
                         :back_off_strategy, :max_attempts, :back_off_time_unit,
                         :event_pool_size, :events_sleep_times

          def configure
            yield config
          end

          def consumes(topic_name, options = {})
            config.topic = topic_name
            config.dlq_topic = config.topic[0,60].strip + '-dlq'
            options.each { |k, v| config.send "#{k}=", v }
          end

          def full_topic_name
            prefix   = ::Tiki::Torch.config.topic_prefix
            new_name = topic.to_s
            return new_name if new_name.start_with? prefix

            "#{prefix}#{new_name}"
          end

          def full_dlq_topic_name
            prefix   = ::Tiki::Torch.config.topic_prefix
            new_name = dlq_topic.to_s
            return new_name if new_name.start_with? prefix

            "#{prefix}#{new_name}"
          end

        end
      end
    end
  end
end
