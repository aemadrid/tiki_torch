# frozen_string_literal: true

class ExceptionalConsumer < Tiki::Torch::Consumer
  consumes 'exceptional'

  def process
    raise 'oh oh'
  rescue => e
    log_exception e, weird: 'error'
  end
end
