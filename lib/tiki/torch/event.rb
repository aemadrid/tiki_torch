module Tiki
  module Torch
    class Event

      extend Forwardable
      include Logging

      attr_reader :message, :payload, :properties

      def initialize(message)
        @message              = message
        @payload, @properties = Torch::Transcoder.decode message.body
        @finished             = false
      end

      delegate [:[]] => :payload
      delegate [:body, :attempts, :timestamp, :finish, :touch, :requeue] => :message

      def message_id
        properties[:message_id]
      end

      alias :id :message_id

      def short_id
        message_id[0,3] + message_id[-3,3]
      end

      def parent_message_id
        properties[:parent_message_id] || ' ' * 32
      end

      alias :parent_id :parent_message_id

      def parent_short_id
        parent_message_id[0,3] + parent_message_id[-3,3]
      end

      def finished?
        @finished
      end

      def touch
        debug "Touching ##{short_id} ..."
        res = message.touch
        debug_var :res, res
        res
      end

      def finish
        return false if finished?

        debug "Finishing ##{short_id} ..."
        res       = message.finish
        @finished = true
        debug_var :res, res
        res
      end

      def requeue(timeout = 0)
        return false if finished?

        debug "Requeueing ##{short_id} ..."
        res       = message.requeue timeout
        @finished = true
        debug_var :res, res
        res
      end

      def to_s
        attrs = {
          message_id: message_id,
          body:       body.size,
          payload:    payload.class.name,
          attempts:   attempts,
          timestamp:  timestamp,
        }
        "#<#{self.class.name} #{attrs.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')}>"
      end

      alias :inspect :to_s

    end
  end
end