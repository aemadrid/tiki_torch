# frozen_string_literal: true

class FailingConsumer < Tiki::Torch::Consumer
  consumes 'failing', visibility_timeout: 1, use_dlq: true, max_attempts: 2

  def process
    raise 'I like to fail'
  end

  def on_failure(exception)
    super
    debug 'failing ...'
    $lines << %w[failed left_for_dead].join(':')
  end
end
