require 'redistat'

module Tiki
  module Torch
    module Monitoring
      class StatsStore

        include Redistat::Model

        scope Monitoring.config.scope
        depth Monitoring.config.depth
        expire Monitoring.config.expire_options
        store_event Monitoring.config.store_event
        hashed_label Monitoring.config.hashed_label

      end

      extend self

      def store
        StatsStore
      end

    end
  end
end
