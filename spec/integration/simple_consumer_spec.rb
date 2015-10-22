describe SimpleConsumer, integration: true, polling: true do
  context 'processing' do
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
