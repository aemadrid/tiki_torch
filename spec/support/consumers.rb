module TestConsumerHelper

  private

  def sleep_if_necessary(period_time = 0.1, touch_event = false)
    secs = payload.is_a?(Hash) ? payload[:sleep_time].to_f : nil
    if secs
      wake_up = Time.now + secs
      debug "> Sleeping for until #{wake_up} ..."
      while Time.now < wake_up
        sleep period_time
        event.touch if touch_event
      end
    end
  end

end

class SimpleConsumer < Tiki::Torch::Consumer

  topic 'test.single'
  channel 'events'

  def process
    $lines << payload
  end

end

class SleepyConsumer < Tiki::Torch::Consumer

  include TestConsumerHelper

  topic 'test.sleepy'
  channel 'events'

  def process
    sleep_if_necessary
    $lines << payload[:message]
  end

end

class SlowConsumer < Tiki::Torch::Consumer

  topic 'test.slow'
  channel 'events'

  self.msg_timeout = 1_000

  def process
    $lines << 'started'
    done_time = Time.now + payload[:sleep_time]
    while Time.now < done_time
      $lines << 'waiting'
      event.touch
      sleep payload[:period_time]
    end
    $lines << 'ended'
  end

end

class MultipleFirstConsumer < Tiki::Torch::Consumer

  include TestConsumerHelper

  topic 'test.multiple'
  channel 'first'

  def process
    $lines << "c1:#{payload}"
    sleep_if_necessary
  end

end

class MultipleSecondConsumer < Tiki::Torch::Consumer

  include TestConsumerHelper

  topic 'test.multiple'
  channel 'second'

  def process
    $lines << "c2:#{payload}"
    sleep_if_necessary
  end

end

class FailingConsumer < Tiki::Torch::Consumer

  topic 'test.failing'
  channel 'events'

  self.max_attempts       = 3
  self.back_off_time_unit = 100 # ms

  def process
    raise 'I like to fail'
  end

  def on_failure(exception)
    super

    $lines << ['failed', attempts.to_s, (back_off.requeue? ? 'requeued' : 'dead')].join(':')
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

class TextProcessorConsumer < Tiki::Torch::Consumer

  topic 'test.reentrant'
  channel 'events'

  def process
    text = payload.to_s
    return [:error, 'missing text'] if text.empty?

    head, tail = text[0, 1], text[1..-1]

    publish self.class.topic, tail unless tail.empty?
    $lines << "#{head}:#{tail}"
  end

end

class ConcurrentConsumer < Tiki::Torch::Consumer

  include TestConsumerHelper

  topic 'test.concurrent'
  channel 'events'

  def process
    $lines << 'started'
    puts "waiting for #{payload} ..."
    sleep_if_necessary
    $lines << 'ended'
  end

end
