describe 'sleepy consumers', integration: true do
  let(:consumer) { SleepyConsumer }

  it 'receives multiple messages' do
    max = 4
    max.times { |nr| Tiki::Torch.publish consumer.topic, message: "l#{nr + 1}", sleep_time: 0.5 }

    wait_for(0.25) { expect($messages.payloads.map{|x| x[:message] }).to eq [] }
    wait_for(2.0) { expect($messages.payloads.map{|x| x[:message] }).to eq %w{ l1 l2 l3 l4 } }
  end
end
