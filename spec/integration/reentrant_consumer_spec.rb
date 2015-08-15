describe 'reentrant consumers', integration: true do
  let(:consumer) { TextProcessorConsumer }

  it 'receives one message that produces several children messages' do
    Tiki::Torch.publish consumer.topic, 'abc'
    wait_for 1

    expect($messages.payloads).to eq %w{ abc bc c }
    expect($messages.results).to eq [[:ok, 'a'], [:ok, 'b'], [:ok, 'c']]

    exp_parent_message_ids = $messages.all.map { |x| x.properties[:parent_message_id] }
    act_parent_message_ids = [nil] + $messages.message_ids[0..-2]
    expect(exp_parent_message_ids).to eq act_parent_message_ids
  end
end
