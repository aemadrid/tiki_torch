module Tiki
  module Torch
    class Consumer

      extend Forwardable

      include Logging

      include Settings
      include Hooks
      include Publishing

      def self.inherited(subclass)
        ConsumerRegistry.add subclass
      end

      def initialize(event, broker)
        @event = event
        @broker = broker
      end

      attr_reader :event, :broker

      delegate [:message, :payload, :properties] => :event

      def to_s
        %{#<#{self.class.name} event=#{event}>}
      end

      alias :inspect :to_s

    end
  end
end