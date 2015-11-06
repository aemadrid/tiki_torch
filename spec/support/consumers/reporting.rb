class ReportingConsumer < Tiki::Torch::Consumer

  consumes 'reporting'

  def process
    debug '> adding $line (processing) ...'
    case payload[:status]
      when 'ok'
        true
      when 'meh'
        false
      else
        raise "Unknown status [#{payload[:status]}]"
    end
  end

  def on_success(result)
    super
    debug '> adding $line succeeded ...'
    $lines << "success"
  end

  def on_failure(exception)
    super
    debug '> adding $line failed ...'
    $lines << "failure"
  end

end