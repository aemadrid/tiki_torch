describe 'sleepy consumers', integration: true do
  let(:consumer) { SlowConsumer }

  it 'receives one message' do
    Tiki::Torch.publish consumer.topic, 4

    wait_for(0.25) { expect($messages.size).to eq 0 }
    wait_for(0.25) { expect($messages.size).to eq 0 }
    wait_for(0.25) { expect($messages.size).to eq 0 }
    wait_for(0.25) { expect($messages.size).to eq 0 }
    wait_for(0.25) { expect($messages.size).to eq 1 }
  end
end
