describe 'custom consumer', integration: true do
  let(:consumer) { CustomizedConsumer }

  it 'receives successful message and overrides successful hooks' do
    Tiki::Torch.publish consumer.topic, status: 'ok'
    $lines.wait_for_size 3

    expect($lines.all).to eq ['started', 'succeeded with true', 'end']
  end

  it 'receives meh message and overrides success hook' do
    Tiki::Torch.publish consumer.topic, status: 'meh'
    $lines.wait_for_size 3

    expect($lines.all).to eq ['started', 'succeeded with false', 'end']
  end

  it 'receives failed message and overrides failure hook' do
    Tiki::Torch.publish consumer.topic, status: 'something else'
    $lines.wait_for_size 3

    expect($lines.all).to eq ['started', 'failed with RuntimeError : Unknown status [something else]', 'end']
  end
end
