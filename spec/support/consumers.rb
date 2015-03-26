class SimpleConsumer < Tiki::Torch::Consumer

  topic 'test.single.events'
  channel 'events'
  max_in_flight 1

  def process
    debug "message : #{message.local_methods}"
    debug "message : #{message.inspect}"
    $messages.add self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

class MultipleFirstConsumer < Tiki::Torch::Consumer

  topic 'test.multiple.events'
  channel 'first'
  max_in_flight 1

  def process
    $messages.add self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

class MultipleSecondConsumer < Tiki::Torch::Consumer

  topic 'test.multiple.events'
  channel 'second'
  max_in_flight 1

  def process
    $messages.add self.class.name, event
    sleep payload[:sleep_time] if payload.is_a?(Hash) && payload[:sleep_time]
  end

end

Nsq::Message
Nsq::Connection