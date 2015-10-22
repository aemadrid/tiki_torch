class SimpleConsumer < Tiki::Torch::Consumer

  consumes 'simple'

  def process
    $lines << payload
  end

end