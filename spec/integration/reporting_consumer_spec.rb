describe ReportingConsumer do
  context 'monitoring', integration: true, polling: true do
    let!(:time_ago) { 5.seconds.ago }
    let!(:start_time) { Time.now }
    context 'publishing' do
      let(:action) { :published }
      it 'reports numbers since' do
        expect(consumer.count_since(action, time_ago)).to eq 0
        expect(consumer.published_since?(time_ago)).to eq false

        3.times { consumer.publish status: 'ok' }
        $lines.wait_for_size 3, 3

        expect(consumer.count_since(action, start_time)).to eq 3
        expect(consumer.published_since?(start_time)).to eq true
      end
    end
    context 'pop' do
      let(:action) { :pop }
      it 'reports numbers since' do
        expect(consumer.count_since(action, time_ago)).to eq 0

        3.times { consumer.publish status: 'ok' }
        sleep 1
        $lines.wait_for_size 3, 10

        expect(consumer.count_since(action, start_time)).to eq(REAL_SQS ? 3 : 2)
      end
    end
    context 'received' do
      let(:action) { :received }
      it 'reports numbers since' do
        expect(consumer.count_since(action, time_ago)).to eq 0

        3.times { consumer.publish status: 'ok' }
        $lines.wait_for_size 3, 3

        expect(consumer.count_since(action, start_time)).to eq 3
      end
    end
    context 'succeeding' do
      let(:action) { :success }
      it 'reports numbers since' do
        expect(consumer.count_since(action, time_ago)).to eq 0

        3.times { consumer.publish status: 'ok' }
        $lines.wait_for_size 3, 10

        expect(consumer.count_since(action, start_time)).to eq 3
      end
    end
    context 'failing' do
      let(:action) { :failure }
      it 'reports numbers since' do
        expect(consumer.count_since(action, time_ago)).to eq 0

        3.times { consumer.publish status: 'unknown' }
        $lines.wait_for_size 3, 20

        expect(consumer.count_since(action, start_time)).to eq 3
      end
    end
  end
end
