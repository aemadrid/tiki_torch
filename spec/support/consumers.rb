class SimpleConsumer < Tiki::Torch::Consumer

  consumes 'test.single'

  def process
    $lines << payload
  end

end

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

class SleepyConsumer < Tiki::Torch::Consumer

  include TestConsumerHelper

  consumes 'test.sleepy'

  def process
    sleep_if_necessary
    $lines << payload[:message]
  end

end

class SlowConsumer < Tiki::Torch::Consumer

  consumes 'test.slow', msg_timeout: 1_000

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

  consumes 'test.multiple', channel: 'first'

  def process
    $lines << "c1:#{payload}"
    sleep_if_necessary
  end

end

class MultipleSecondConsumer < Tiki::Torch::Consumer

  include TestConsumerHelper

  consumes 'test.multiple', channel: 'second'

  def process
    $lines << "c2:#{payload}"
    sleep_if_necessary
  end

end

class FailingConsumer < Tiki::Torch::Consumer

  consumes 'test.failing',
           max_attempts:       3,
           back_off_time_unit: 100 # ms

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

    $lines << "failed with #{exception.class} : #{exception.message}"
  end

  def on_end
    super

    $lines << 'end'
  end

end

class CustomizedConsumer < Tiki::Torch::Consumer

  include CustomConsumer

  consumes 'test.customized'

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

  consumes 'test.reentrant'

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

  consumes 'test.concurrent'

  def process
    $lines << 'started'
    sleep_if_necessary
    $lines << 'ended'
  end

end

class AdderConsumer < Tiki::Torch::Consumer

  include TestConsumerHelper

  consumes 'test.adder'

  def process
    puts ">>> process started ..."
    numbers = payload[:numbers]
    res     = numbers.map { |x| x.to_i }.inject(0) { |t, x| t + x }
    puts ">>> lines ..."
    $lines << "#{numbers.inspect}|#{res}"
    puts ">>> sleeping if necessary ..."
    sleep_if_necessary
    puts ">>> done ..."
    res
  end

end

class StatsConsumer < Tiki::Torch::Consumer

  consumes 'test.stats'

  def process
    $lines << 'done'
  end

end
