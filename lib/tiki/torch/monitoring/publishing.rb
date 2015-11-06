module Tiki
  module Torch
    module Monitoring
      module Publishing

        extend self

        def count_published(topic_name, _, _)
          key = "published:#{Utils.simplified_name(topic_name)}"
          Monitoring.store.store key, count: 1
        end

      end
    end

    class Publisher

      private

      def monitor_publish(topic_name, payload, properties)
        debug "going to publish #{topic_name} ..."
        Monitoring::Publishing.count_published topic_name, payload, properties
        debug "published to #{topic_name} ..."
      end

    end
  end
end