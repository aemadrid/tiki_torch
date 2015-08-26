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

        setup_connection setup_options(options)
      end

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
        }.tap do |hsh|
          hsh.delete_if{|_,v| v.is_a?(Array) && v.empty?}
        end
      end

      def setup_connection(options)
        @connection = ::Nsq::Consumer.new options
      end

    end
  end
end
