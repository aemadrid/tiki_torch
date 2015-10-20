class SimpleConsumer < Tiki::Torch::Consumer

  consumes 'test.simple'

  def process
    $lines << payload
  end

end