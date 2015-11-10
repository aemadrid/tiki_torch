describe ConcurrentConsumer, integration: true do
  it 'process messages concurrently' do
    3.times { consumer.publish sleep_time: 2 }
    $lines.wait_for_size 6

    expect($lines.all[0,2]).to eq %w{ started started  }
  end
end