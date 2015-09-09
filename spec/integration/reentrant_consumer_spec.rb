describe 'reentrant consumers', integration: true do
  before(:context)  { $consumer = TextProcessorConsumer }

  it 'receive one message that produce another message until no longer necessary' do
    Tiki::Torch.publish $consumer.topic, 'abc'
    $lines.wait_for_size 3

    expect($lines.all).to eq %w{ a:bc b:c c: }
  end
end
