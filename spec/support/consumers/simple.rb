# frozen_string_literal: true

class SimpleConsumer < Tiki::Torch::Consumer
  consumes 'simple'

  def process
    debug "processing (#{payload.class.name}) #{payload.inspect}"
    $lines << payload
  end
end
