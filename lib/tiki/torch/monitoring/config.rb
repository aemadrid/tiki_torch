module Tiki
  module Torch
    module Monitoring
      class Config

        include Virtus.model
        include Logging

        attribute :scope, String, default: lambda { |_, _| ENV.fetch('REDISTAT_SCOPE', 'torch:stats') }, lazy: true

        attribute :depth, Symbol, default: lambda { |_, _| ENV.fetch('REDISTAT_DEPTH', 'sec').to_sym }, lazy: true
        attribute :store_event, Boolean, default: lambda { |_, _| ENV.fetch('REDISTAT_STORE_EVENT', 'false') == 'true' }, lazy: true
        attribute :hashed_label, Boolean, default: lambda { |_, _| ENV.fetch('REDISTAT_HASHED_LABEL', 'false') == true }, lazy: true

        attribute :expire_sec, Integer, default: lambda { |_, _| ENV.fetch('REDISTAT_EXP_SEC', 90.seconds).to_i }, lazy: true
        attribute :expire_min, Integer, default: lambda { |_, _| ENV.fetch('REDISTAT_EXP_MIN', 3.hours).to_i }, lazy: true
        attribute :expire_hour, Integer, default: lambda { |_, _| ENV.fetch('REDISTAT_EXP_HOUR', 7.days).to_i }, lazy: true
        attribute :expire_day, Integer, default: lambda { |_, _| ENV.fetch('REDISTAT_EXP_DAY', 3.months).to_i }, lazy: true

        def expire_options
          options = {
            sec:  expire_sec,
            min:  expire_min,
            hour: expire_hour,
            day:  expire_day,
          }
          options.delete_if { |_, v| v.nil? }
          options
        end

        def to_s
          "#<T:T:M:Config" +
            " scope=#{scope.inspect}" +
            " depth=#{depth.inspect}" +
            " expire=#{expire_options.inspect}" +
            ">"
        end

        alias :inspect :to_s

      end

      extend self

      def config
        @config ||= Config.new
      end

      def configure
        yield config
      end

      config

    end
  end
end