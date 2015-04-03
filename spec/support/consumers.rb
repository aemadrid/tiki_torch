class SimpleConsumer < Tiki::Torch::Consumer

  topic 'test.single.events'
  channel 'events'
  max_in_flight 1

  def process
    $messages.add_event self.class.name, event
  end

end

class SleepyConsumer < Tiki::Torch::Consumer

  topic 'test.sleepy.events'
  channel 'events'
  max_in_flight 1

  def process
    sleep_if_necessary
    $messages.add_event self.class.name, event
  end

  private

  def sleep_if_necessary
    if (secs = payload[:sleep_time].to_f) > 0
      debug "> Sleeping for #{secs} ..."
      sleep secs
    end
  end

end

class SlowConsumer < Tiki::Torch::Consumer

  topic 'test.slow.events'
  channel 'events'
  max_in_flight 1

  def process
    payload.times do |nr|
      info "#{nr + 1}/#{payload} | waiting ..."
      sleep 0.25
      event.touch
    end
    $messages.add_event self.class.name, event
  end

  private

  def sleep_if_necessary
    if (secs = payload[:sleep_time].to_f) > 0
      debug "> Sleeping for #{secs} ..."
      sleep secs
    end
  end

end

class MultipleFirstConsumer < Tiki::Torch::Consumer

  topic 'test.multiple.events'
  channel 'first'
  max_in_flight 1

  def process
    $messages.add_event self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

class MultipleSecondConsumer < Tiki::Torch::Consumer

  topic 'test.multiple.events'
  channel 'second'
  max_in_flight 1

  def process
    $messages.add_event self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end
