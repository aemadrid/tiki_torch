require 'set'

module Tiki
  module Torch
    class Consumer

      extend Forwardable

      include Logging

      include Settings
      include Publishing
      include Hooks
      include BackOff
      include Flow
      include DLQ
      include Monitoring

      def self.inherited(subclass)
        ConsumerBroker.register_consumer subclass
      end

      def initialize(event)
        @event = event
      end

      attr_reader :event

      delegate [:message, :payload, :properties, :message_id, :short_id] => :event
      delegate [:body, :attempts, :timestamp] => :message

    end
  end
end