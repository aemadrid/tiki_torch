describe SimpleConsumer do
  context 'basic', focus: true do
    it('topic             ') { expect(consumer.topic).to eq 'test.simple' }
    it('topic_prefix      ') { expect(consumer.topic_prefix).to eq config.topic_prefix }
    it('channel           ') { expect(consumer.channel).to eq config.channel }
    it('dlq_postfix       ') { expect(consumer.dlq_postfix).to eq config.dlq_postfix }
    it('visibility_timeout') { expect(consumer.visibility_timeout).to eq config.visibility_timeout }
    it('message_retention ') { expect(consumer.message_retention_period).to eq config.message_retention_period }
    it('max_in_flight     ') { expect(consumer.max_in_flight).to eq config.max_in_flight }
    it('max_attempts      ') { expect(consumer.max_attempts).to eq config.max_attempts }
    it('event_pool_size   ') { expect(consumer.event_pool_size).to eq config.event_pool_size }
    it('transcoder_code   ') { expect(consumer.transcoder_code).to eq config.transcoder_code }
    it('sleep_times       ') { expect(consumer.events_sleep_times).to eq config.events_sleep_times }
    it('queue_name        ') { expect(consumer.queue_name).to eq "#{config.topic_prefix}-test.simple-events" }
  end
  context 'processing', integration: true, polling: true do
    context 'multiple' do
      let(:expected) { qty.times.map { |x| 's%02i' % x } }
      shared_examples 'multiple send and receive' do
        it 'properly' do
          qty.times { |nr| consumer.publish 's%02i' % nr }

          $lines.wait_for_size qty, qty / 4.0 * 3

          expect($lines.size).to eq qty
          expect($lines.sorted).to eq expected
        end
      end
      context 'send/receive #1' do
        let(:qty) { 4 }
        it_behaves_like 'multiple send and receive'
      end
      context 'send/receive #2' do
        let(:qty) { 14 }
        it_behaves_like 'multiple send and receive'
      end
      context 'send/receive #3' do
        let(:qty) { 54 }
        it_behaves_like 'multiple send and receive'
      end
    end
  end
end
