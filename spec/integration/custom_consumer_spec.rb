
describe 'custom consumers', integration: true do
  let(:consumer) { CustomizedConsumer }
  before(:each) { clear_consumer consumer }

  it 'receives successful message and overrides successful hooks' do
    LogMessages.clear

    Tiki::Torch.publish consumer.topic, status: 'ok'
    wait_for 0.5

    expect(LogMessages.messages).to eq ['started', 'succeeded with true', 'end']
  end

  it 'receives meh message and overrides successful hooks' do
    LogMessages.clear

    Tiki::Torch.publish consumer.topic, status: 'meh'
    wait_for 0.5

    expect(LogMessages.messages).to eq ['started', 'succeeded with false', 'end']
  end

  it 'receives failed message and overrides successful hooks' do
    LogMessages.clear

    Tiki::Torch.publish consumer.topic, status: 'something else'
    wait_for 0.5

    expect(LogMessages.messages).to eq ['started', 'failed with RuntimeError : Unknown status [something else]', 'end']
  end
end
