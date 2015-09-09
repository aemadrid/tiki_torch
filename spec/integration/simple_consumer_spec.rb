describe 'simple consumers', integration: true do
  before(:context) { $consumer = SimpleConsumer }

  it 'receive multiple messages' do
    4.times { |nr| Tiki::Torch.publish $consumer.topic, "s#{nr + 1}" }
    $lines.wait_for_size 4

    expect($lines.all.sort).to eq %w{ s1 s2 s3 s4 }
  end
end
