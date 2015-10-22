class FailingConsumer < Tiki::Torch::Consumer

  consumes 'failing', visibility_timeout: 3, use_dlq: true, max_attempts: 3

  def process
    raise 'I like to fail'
  end

  def on_failure(exception)
    super

    $lines << ['failed', 'left_for_dead'].join(':')
  end

end
