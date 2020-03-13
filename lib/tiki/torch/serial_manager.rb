module Tiki
  module Torch
    class SerialManager

      include Logging
      extend Forwardable

      attr_reader :client, :pollers, :publisher

      def_delegator :@publisher, :publish

      def initialize(client = Torch.client)
        @client = client
        @pollers = build_pollers
        @publisher = build_publisher
        trap_signals
        at_exit { stop_polling }
      end

      def running?
        @running.to_s == 'true'
      end

      def start_polling
        info "starting to poll ..."
        @running = true

        while running?
          pollers.each do |poller|
            handle_signals
            break unless running?

            poller.run_once
            wait
          end
          wait
        end
      end

      alias start start_polling

      def wait
        return unless running?

        sleep Torch.config.serial_wait_secs
      end

      def stop_polling
        return unless running?

        info "stop polling ..."
        @running = false
      end

      alias stop stop_polling

      def to_s
        %{#<T:T:SerialManager pollers=#{pollers.size}>}
      end

      alias :inspect :to_s

      private

      def build_pollers
        ConsumerRegistry.all.map do |consumer|
          ConsumerBuilder.build consumer, client
          SerialPoller.new consumer, client
        end
      end

      def build_publisher
        Publishing::Publisher.new
      end

      def trap_signals
        @signals = []
        %w[INT TERM].each do |sig|
          trap(sig) do
            info "Captured signal [#{sig}]"
            @signals << sig
          end
        end
      end

      def handle_signals
        while (sig = @signals.shift)
          info "Handling signal [#{sig}] ..."
          case sig
          when 'INT', 'TERM'
            stop_polling
          end
        end
      end
    end

    extend self

    def build_default_serial_manager
      SerialManager.new
    end

    attr_writer :serial_manager

    def serial_manager
      @serial_manager ||= build_default_serial_manager
    end

  end
end
