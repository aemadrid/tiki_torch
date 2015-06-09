require 'concurrent/atomic/atomic_fixnum'

module Tiki
  module Torch
    class Stats

      def initialize(*names)
        @counters = {}
        names.map { |x| counter x }
      end

      def counter(name, initial_value = 0)
        safe_name = key name
        found     = @counters[safe_name]
        return found if found

        @counters[safe_name] = Concurrent::AtomicFixnum.new initial_value
      end

      alias :[] :counter

      def increment(name)
        counter(name).increment
      end

      def to_hash
        @counters.inject({}) { |h, (k, v)| h[k] = v.value; h }
      end

      def to_s
        %{#<#{self.class.name} #{to_hash.map{|k,v| "#{k}=#{v}"}.join(' ')}>}
      end

      alias :inspect :to_s

      private

      def key(name)
        name.to_s.underscore.to_sym
      end

    end
  end
end