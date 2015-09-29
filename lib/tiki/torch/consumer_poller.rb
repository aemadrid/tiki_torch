module Tiki
  module Torch
    class ConsumerPoller

      include Logging
      extend Forwardable

      attr_reader :connection

      delegate [:connected?, :pop] => :connection

      def initialize(options = {})
        raise 'Missing topic name' unless options[:topic]
        raise 'Missing channel name' unless options[:channel]

        @options = setup_options options
        setup_connection @options
      end

      def close
        clear_queue
        close_connection
      end

      def to_s
        %{#<CP|#{@options[:topic]}|#{@options[:channel]}|#{connection.size}>}
      end

      alias :inspect :to_s

      private

      def setup_options(options)
        {
          nsqd:               Array(options[:nsqd] || Torch.config.nsqd).flatten,
          nsqlookupd:         Array(options[:nsqlookupd] || Torch.config.nsqlookupd).flatten,
          topic:              options[:topic],
          channel:            options[:channel],
          max_in_flight:      options[:max_in_flight] || Torch.config.max_in_flight,
          discovery_interval: options[:discovery_interval] || Torch.config.discovery_interval,
          msg_timeout:        options[:msg_timeout] || Torch.config.msg_timeout,
          queue:              options[:queue] || Torch.config.queue_class.new
        }.tap do |hsh|
          hsh.delete_if { |_, v| v.is_a?(Array) && v.empty? }
        end
      end

      def setup_connection(options)
        @connection = ::Nsq::Consumer.new options
      end

      def clear_queue
        while connection.size > 0
          debug "T:#{@options[:topic]} | C:#{@options[:channel]} | requeuing messages #{connection.size} in queue ..."
          pop.requeue(1)
        end
      end

      def close_connection
        debug "T:#{@options[:topic]} | C:#{@options[:channel]} | closing connection  ..."
        connection.terminate
      end

    end
  end
end
