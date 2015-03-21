# -*- encoding: utf-8 -*-

require 'multi_json'
require 'forwardable'

module Tiki
  module Torch
    class Event

      extend Forwardable
      include Logging

      attr_reader :message, :payload, :properties

      def initialize(message)
        # debug_var :message, message
        @message              = message
        @payload, @properties = Torch::Transcoder.decode message.body
      end

      delegate [:[]] => :payload
      delegate [:body, :attempts, :timestamp, :finish, :touch, :requeue] => :message

      def message_id
        properties[:message_id]
      end

      def finish
        debug "Finishing ##{message_id} ..."
        res = message.finish
        debug_var :res, res
        res
      end

      def requeue(timeout = 0)
        debug "Requeueing ##{message_id} ..."
        res = message.requeue timeout
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
        "#<Tiki::Torch::Event #{attrs.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')}>"
      end

      alias :inspect :to_s

    end
  end
end