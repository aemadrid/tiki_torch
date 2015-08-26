require 'virtus'

module Tiki
  module Torch
    class Consumer
      module Settings

        class Config

          include Virtus.model

          attribute :topic, String, default: lambda { |config, _| config.consumer.name.underscore }
          attribute :channel, String, default: 'events'

          attribute :nsqlookupd, Array[String], default: lambda { |_, _| ::Tiki::Torch.config.nsqlookupd }
          attribute :nsqd, Array[String], default: lambda { |_, _| ::Tiki::Torch.config.nsqd }

          attribute :topic_prefix, String, default: lambda { |_, _| ::Tiki::Torch.config.topic_prefix }
          attribute :max_in_flight, Integer, default: lambda { |_, _| ::Tiki::Torch.config.max_in_flight }
          attribute :discovery_interval, Integer, default: lambda { |_, _| ::Tiki::Torch.config.discovery_interval }
          attribute :msg_timeout, Integer, default: lambda { |_, _| ::Tiki::Torch.config.msg_timeout }

          attribute :back_off_strategy, Integer, default: lambda { |_, _| ::Tiki::Torch.config.back_off_strategy }
          attribute :max_attempts, Integer, default: lambda { |_, _| ::Tiki::Torch.config.max_attempts }
          attribute :back_off_time_unit, Integer, default: lambda { |_, _| ::Tiki::Torch.config.back_off_time_unit }

          attribute :event_pool_size, Integer, default: lambda { |_, _| ::Tiki::Torch.config.event_pool_size }
          attribute :events_sleep_times, Integer, default: lambda { |_, _| ::Tiki::Torch.config.events_sleep_times }

          attribute :colorized, Boolean, default: lambda { |_, _| ::Tiki::Torch.config.colorized }

          attr_reader :consumer

          def initialize(consumer, options = {})
            @consumer = consumer
            super(options)
          end

          def topic=(name)
            name = "#{topic_prefix}#{name}" unless name.to_s.start_with? topic_prefix
            super name
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
                         :topic, :channel,
                         :nsqlookupd, :nsqd,
                         :topic_prefix, :max_in_flight, :discovery_interval, :msg_timeout,
                         :back_off_strategy, :max_attempts, :back_off_time_unit,
                         :event_pool_size, :events_sleep_times,
                         :colorized

          def configure
            yield config
          end

          def consumes(topic_name, options = {})
            config.topic = topic_name
            options.each { |k, v| config.send "#{k}=", v }
          end

        end
      end
    end
  end
end
