module Tiki
  module Torch
    class ConsumerRegistry

      class << self

        def all
          @all ||= Set.new
        end

        def add(consumer_class)
          all.add consumer_class
        end

      end
    end
  end
end