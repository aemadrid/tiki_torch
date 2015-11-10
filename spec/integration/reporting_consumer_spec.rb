describe ReportingConsumer do
  context 'monitoring' do
    let!(:time_ago) { 5.seconds.ago }
    let!(:start_time) { Time.now }
    context 'singular consumer', integration: true do
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
        it 'reports numbers since', focus: true do
          expect(consumer.count_since(action, time_ago)).to eq 0

          3.times { consumer.publish status: 'ok' }
          sleep 1
          $lines.wait_for_size 3, 10

          expect([2,3]).to include consumer.count_since(action, start_time)
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
    context 'all plus aggregate' do
      let(:reporting_entries) { { 3 => mk_stats(5, 4), 6 => mk_stats(8, 7), 12 => mk_stats(12, 9) } }
      let(:simple_entries) { { 2 => mk_stats(7), 7 => mk_stats(11, 9), 13 => mk_stats(6) } }
      let(:consumers) { [ReportingConsumer, SimpleConsumer] }
      let(:now) { Time.now }
      let(:options) { { unit: unit, final: now } }
      subject { Tiki::Torch::Monitoring.stats times, options }
      shared_examples 'a stats query hash' do
        it 'properly' do
          store_stats reporting_entries, unit, ReportingConsumer
          store_stats simple_entries, unit, SimpleConsumer

          # subject
          puts "[#{unit}] subject #{subject.to_yaml}"
          expect(subject).to be_a Hash
          # Basic
          expect(subject[:unit]).to eq unit
          expect(subject[:times]).to eq times
          expect(subject[:final]).to eq now
          expect(subject[:scope]).to eq Tiki::Torch::Monitoring.config.scope
          # Labels
          expect(subject[:labels]).to eq consumers.map { |x| x.monitor_name }
          # Units
          expect(subject[:units].size).to eq times.last
          # consumers
          expect(subject[:consumers].size).to eq consumers.size
          expect(subject[:consumers].keys).to eq consumers.map { |x| x.name }
        end
      end
      context 'on minutes', integration: true do
        let(:unit) { :minutes }
        let(:times) { [5, 10, 15] }
        it_behaves_like 'a stats query hash'
      end
      context 'on hours', integration: true do
        let(:unit) { :hours }
        let(:times) { [6, 12, 24] }
        it_behaves_like 'a stats query hash'
      end
      context 'on days', integration: true do
        let(:unit) { :days }
        let(:times) { [7, 14, 28] }
        it_behaves_like 'a stats query hash'
      end

      def mk_stats(pub, suc = pub, fail = nil, pop = 1, rec = nil)
        {
          published: pub,
          pop:       pop,
          received:  rec || pub,
          success:   suc || pub,
          failure:   fail || (pub - suc)
        }
      end

      def store_stats(entries, unit, consumer)
        entries.each do |mins, stats|
          stats.each do |action, qty|
            consumer.store_stat action, qty, mins.send(unit).ago if qty > 0
          end
        end
      end
    end
  end
end
