describe ConcurrentConsumer, integration: true, polling: true do
  it 'process messages concurrently' do
    3.times { consumer.publish sleep_time: 1.5 }
    $lines.wait_for_size 6

    expect($lines.all).to eq %w{ started started started ended ended ended }
  end
end