class SimpleConsumer < Tiki::Torch::Consumer

  topic 'test.single'
  channel 'events'

  def process
    $messages.add_event self.class.name, event
  end

end

class SleepyConsumer < Tiki::Torch::Consumer

  topic 'test.sleepy'
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

  topic 'test.slow'
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

  topic 'test.multiple'
  channel 'first'

  def process
    $messages.add_event self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

class MultipleSecondConsumer < Tiki::Torch::Consumer

  topic 'test.multiple'
  channel 'second'

  def process
    $messages.add_event self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

class FailingConsumer < Tiki::Torch::Consumer

  topic 'test.failing'
  channel 'events'

  self.max_attempts       = 3
  self.back_off_time_unit = 100 # ms

  def process
    $messages.add_event self.class.name, event
    raise 'I like to fail'
  end

  def on_failure(exception)
    super

    $lines << (back_off.requeue? ? 'requeued' : 'dead')
  end

end

module CustomConsumer

  def on_start
    super

    $lines << 'started'
  end

  def on_success(result)
    super

    $lines << "succeeded with #{result.inspect}"
  end

  def on_failure(exception)
    super

    puts "on_failure start ..."
    $lines << "failed with #{exception.class} : #{exception.message}"
    puts "on_failure end ..."
  end

  def on_end
    super

    $lines << 'end'
  end

end

class CustomizedConsumer < Tiki::Torch::Consumer

  include CustomConsumer

  topic 'test.customized'
  channel 'events'

  def process
    debug_var :payload, payload
    case payload[:status]
      when 'ok'
        true
      when 'meh'
        false
      else
        raise "Unknown status [#{payload[:status]}]"
    end
  end

end
