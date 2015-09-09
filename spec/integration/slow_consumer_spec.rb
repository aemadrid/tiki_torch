describe 'slow consumers', integration: true do
  before(:context)  { $consumer =  SlowConsumer  }

  it 'stay alive after message timeout with touch' do
    Tiki::Torch.publish $consumer.topic, sleep_time: 1.25, period_time: 0.5
    $lines.wait_for_size 5

    expect($lines.all).to eq %w{ started waiting waiting waiting ended }
  end
end
