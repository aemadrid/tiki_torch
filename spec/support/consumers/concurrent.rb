# frozen_string_literal: true

class ConcurrentConsumer < Tiki::Torch::Consumer
  include TestingHelpers::Consumer

  consumes 'concurrent'

  def process
    $lines << 'started'
    sleep_if_necessary
    $lines << 'ended'
  end
end
