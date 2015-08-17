describe 'sleepy consumers', integration: true do
  let(:consumer) { SleepyConsumer }

  it 'receive multiple messages and return results in time' do
    4.times { |nr| Tiki::Torch.publish consumer.topic, message: "l#{nr + 1}", sleep_time: 0.3 }

    wait_for(0.1) { expect($lines.all).to eq [] }
    $lines.wait_for_size(4) { expect($lines.all).to eq %w{ l1 l2 l3 l4 } }
  end
end
