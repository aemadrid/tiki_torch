describe 'concurrent consumers', integration: true do
  let(:consumer) { ConcurrentConsumer }

  it 'process messages concurrently' do
    3.times { Tiki::Torch.publish consumer.topic, 0.25 }
    $lines.wait_for_size 6

    expect($lines.all).to eq %w{ started started started ended ended ended }
  end
end
