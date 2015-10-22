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

  consumes 'customized'

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