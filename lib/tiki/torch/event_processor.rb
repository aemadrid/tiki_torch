# -*- encoding: utf-8 -*-

require 'celluloid'

module Tiki
  module Torch
    class EventProcessor

      include Celluloid
      include Logging

      finalizer :finalize

      def process(consumer_class, event)
        consumer_class.process event
      end

      private

      def finalize
        debug "Finalized ##{object_id} ..."
      end

    end
  end
end
