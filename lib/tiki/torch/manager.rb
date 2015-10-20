module Tiki
  module Torch
    class Manager

      include Logging
      extend Forwardable

      attr_reader :client, :config, :brokers, :publisher

      def_delegators :@config,
                     :topic_prefix, :max_in_flight, :discovery_interval, :msg_timeout,
                     :back_off_strategy, :max_attempts, :back_off_time_unit,
                     :transcoder_code, :queue_class,
                     :event_pool_size, :events_sleep_times, :processor_count

      def_delegator :@publisher, :publish

      def initialize(client, options = {})
        @client    = client
        @config    = build_config options
        @brokers   = build_brokers
        @publisher = build_publisher
        at_exit { shutdown }
      end

      def configure
        yield @config
      end

      def brokers_for(pattern)
        brokers.select do |c|
          case pattern
            when Class
              c.consumer == pattern
            when Regexp
              c.name =~ pattern
            when String
              c.name == pattern
            when :all, 'all'
              true
            else
              raise "Unknown pattern [#{pattern.class.name}:#{pattern.inspect}]"
          end
        end
      end

      def start_polling(pattern = /.*/)
        brokers_for(pattern).map do |c|
          debug "[#{pattern}] start #{c.name} : #{c.topic} : #{c.channel}".center(120, '~')
          Concurrent::Future.execute { [c.name, c.start] }
        end.map { |x| x.value }
      end

      def stop_polling(pattern = /.*/)
        brokers_for(pattern).map do |c|
          debug "[#{pattern}] stop #{c.name} : #{c.topic} : #{c.channel}".center(120, '~')
          Concurrent::Future.execute { [c.name, c.stop] }
        end.map { |x| x.value }
      end

      def shutdown
        [
          Concurrent::Future.execute { @brokers.map { |x| x.shutdown } },
          Concurrent::Future.execute { @publisher.shutdown },
        ].map { |x| x.value }
      end

      private

      def build_config(options)
        if options.is_a? Config
          options
        else
          Config.new options
        end
      end

      def build_publisher
        Publisher.new self
      end

      def build_brokers
        ConsumerRegistry.all.map { |consumer| ConsumerBroker.new consumer, self }
      end

    end

    extend self

    def build_default_manager
      Manager.new client, config
    end

    attr_writer :manager

    def manager
      @manager ||= build_default_manager
    end

  end
end
