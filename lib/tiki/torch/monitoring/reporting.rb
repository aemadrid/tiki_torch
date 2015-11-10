module Tiki
  module Torch
    module Monitoring
      class StatsQuery

        UNITS = %i{ minutes hours days }.freeze

        attr_reader :unit, :times, :final, :scope, :keys

        def initialize(*args)
          args.flatten!
          options = args.last.is_a?(Hash) ? args.pop : {}
          @unit   = options.delete(:unit) || :minutes
          raise "Unknown unit [#{@unit}]" unless UNITS.include? @unit
          @final = options.delete(:final) || Time.now
          @scope = options.delete(:scope) || Monitoring.config.scope
          @keys  = options.delete(:keys) || Monitoring::STAT_KEYS
          @times = args.map { |x| x.to_i }.uniq.sort.select { |x| x > 0 }
          raise 'Missing times' if @times.empty?
        end

        def to_hash
          {
            unit:       unit,
            times:      times,
            final:      final,
            scope:      scope,
            keys:       keys,
            labels:     labels,
            units:      units,
            full_stats: full_stats,
            consumers:  consumers,
          }
        end

        private

        def db
          ::Redistat.redis
        end

        def labels
          return @labels if @labels

          name    = "#{scope}#{Redistat::LABEL_INDEX}pop"
          keys    = db.smembers(name) || []
          @labels = keys.sort
        end

        # torch:stats:failure:20151107125139
        # 2015-11-07 12:51:39
        def units
          return @units if @units

          formats = { minutes: '%Y%m%d%H%M', hours: '%Y%m%d%H', days: '%Y%m%d' }
          @units  = times.last.times.map do |nr|
            (final - nr.send(unit)).strftime formats[unit]
          end
        end

        def consumers
          return @consumers if @consumers

          labels.each_with_object({}) do |label, hsh|
            consumer           = ConsumerRegistry.all.find { |x| x.monitor_name == label }
            hsh[consumer.name] = {
              label:      label,
              name:       consumer.name,
              queue_name: consumer.queue_name,
              dlq_name:   consumer.dead_letter_queue_name,
              stats:      stats_for(label),
            }
          end
        end

        # torch:stats : published : testsimpleevents : 2015
        def full_stats
          return @full_stats if @full_stats

          @full_stats = {}

          keys.map do |key|
            labels.map do |label|
              units.each do |unit|
                @full_stats["#{scope}:#{key}:#{label}:#{unit}"] = 0
              end
            end
          end

          entry_keys   = @full_stats.keys.sort
          entry_values = db.mget entry_keys
          entry_keys.each_with_index do |key, idx|
            @full_stats[key] = entry_values[idx]
          end
          @full_stats
        end

        def stats_for(label)
          {}
        end

      end

      extend self

      def stats(*args)
        StatsQuery.new(*args).to_hash
      end

    end
  end
end