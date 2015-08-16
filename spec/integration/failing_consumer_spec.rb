describe 'failing consumers', integration: true do
  let(:consumer) { FailingConsumer }

  it 'receives multiple messages' do
    Tiki::Torch.publish consumer.topic, 'failure'
    $lines.wait_for_size 3

    expect($lines.all).to eq %w{ failed:1:requeued failed:2:requeued failed:3:dead }
  end
end
