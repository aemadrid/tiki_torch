class SimpleConsumer < Tiki::Torch::Consumer

  topic 'test.single.events'
  channel 'events'

  def process
    $messages.add_event self.class.name, event
  end

end

class SleepyConsumer < Tiki::Torch::Consumer

  topic 'test.sleepy.events'
  channel 'events'

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

  def process
    $messages.add_event self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

class MultipleSecondConsumer < Tiki::Torch::Consumer

  topic 'test.multiple.events'
  channel 'second'

  def process
    $messages.add_event self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

class FailingConsumer < Tiki::Torch::Consumer

  topic 'test.failing.events'
  channel 'events'

  self.max_attempts       = 3
  self.back_off_time_unit = 100 # ms

  def process
    $messages.add_event self.class.name, event
    raise 'I like to fail'
  end

end

