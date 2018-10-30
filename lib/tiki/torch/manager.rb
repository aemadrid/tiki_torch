module Tiki
  module Torch

    class Manager

      include Logging
      extend Forwardable

      attr_reader :brokers, :publisher

      def_delegators :config,
                     :prefix, :discovery_interval, :msg_timeout,
                     :back_off_strategy, :max_attempts, :back_off_time_unit,
                     :transcoder_code, :queue_class,
                     :event_pool_size, :events_sleep_times, :processor_count

      def_delegator :@publisher, :publish

      def initialize
        @brokers   = build_brokers
        @publisher = build_publisher
        at_exit { shutdown }
      end

      def client
        Torch.client
      end

      def config
        Torch.config
      end

      def brokers_for(pattern, action = :noop)
        brokers.select do |c|
          case pattern
            when Class
              debug "#{c.name} : #{action} | pattern : Class : #{pattern.inspect}"
              c.consumer == pattern
            when Regexp
              debug "#{c.name} : #{action} | pattern : Regexp : #{pattern.inspect}"
              c.name =~ pattern
            when String
              debug "#{c.name} : #{action} | pattern : String : #{pattern.inspect}"
              c.name == pattern
            when :all, 'all'
              debug "#{c.name} : #{action} | pattern : All : #{pattern.inspect}"
              true
            else
              debug "#{c.name} : #{action} | pattern : Unknown : (#{pattern.class.name}) #{pattern.inspect} ..."
              false
          end
        end
      end

      def start_polling(pattern = :all)
        debug "starting to poll | pattern (#{pattern.class.name}) #{pattern.inspect}"
        brokers_for(pattern, :start).map do |c|
          debug "[#{pattern}] start #{c.name} : #{c.topic} : #{c.channel}".center(90, '~')
          Concurrent::Future.execute { [c.name, c.start] }
        end.map { |x| x.value }
      end

      def stop_polling(pattern = :all)
        debug "stop polling | pattern (#{pattern.class.name}) #{pattern.inspect}"
        brokers_for(pattern, :stop).map do |c|
          debug "[#{pattern}] stop #{c.name} : #{c.topic} : #{c.channel}".center(90, '~')
          Concurrent::Future.execute { [c.name, c.stop] }
        end.map { |x| x.value }
      end

      def shutdown
        [
          Concurrent::Future.execute { @brokers.map { |x| x.shutdown } },
          Concurrent::Future.execute { @publisher.shutdown },
        ].map { |x| x.value }
      end

      def to_s
        %{#<T:T:Manager brokers=#{brokers.size}>}
      end

      alias :inspect :to_s

      private

      def build_publisher
        Publishing::Publisher.new
      end

      def build_brokers
        ConsumerRegistry.all.map { |consumer| ConsumerBroker.new consumer, self }
      end

    end

    extend self

    def build_default_manager
      Manager.new
    end

    attr_writer :manager

    def manager
      @manager ||= build_default_manager
    end

  end
end
