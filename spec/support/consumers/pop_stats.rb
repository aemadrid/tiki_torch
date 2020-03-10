# frozen_string_literal: true

class PopStatsConsumer < Tiki::Torch::Consumer
  include TestingHelpers::Consumer

  consumes 'pop_stats'

  class << self
    def tag
      "r:#{event_pool_size}"
    end

    def pop_results(req_size, found_size, timeout)
      super
      $lines << "r:#{req_size}"
    end
  end
end
