describe 'varied slow consumers', integration: true, performance: true do

  before(:context) { $consumer = VariedSlowConsumer }

  context 'processing' do
    [1, 5, 10, 20, 30, 40, 50, 60].each do |secs|
      it "processes in #{secs}s to a single message" do
        Tiki::Torch.publish $consumer.topic, sleep_time: secs, period_time: secs / 5.0
        took = $lines.wait_for_size 1, secs * 2

        expect($lines.all).to eq %w{ varied_slow }
        expect(took).to be_within(1).of(secs)
      end
    end
  end

  context 'processing' do
    [2, 5, 10, 20, 30].each do |secs|
      [1, 2, 4, 8, 12, 16].each do |qty|
        it "sends #{qty} requests with #{secs}s sleep each and gathers valid results in time", focus: true do
          payload = { sleep_time: secs, period_time: secs / 5.0 - 0.25 }
          options = { timeout: secs * 3 }
          results = []

          took = time_it do
            debug " [ #{Time.now} : requesting ] ".center(120, '=')
            futures = qty.times.map { Tiki::Torch.request $consumer.topic, payload, options }
            debug " [ #{Time.now} : gathering ] ".center(120, '=')
            results = futures.map { |x| x.value }
            debug " [ #{Time.now} : done ] ".center(120, '=')
          end

          found_hsh = results.each_with_object(Hash.new(0)) { |x, h| h[x.to_s] += 1; h['total'] += 1 }

          puts "found_hsh : (#{found_hsh.class.name}) #{found_hsh.to_yaml}"
          ratio = 1 + qty * (qty > $consumer.event_pool_size ? 1 : 0.25)

          expect(found_hsh['']).to eq(0), "expected list of results to have no failures but found #{found_hsh['']}/#{found_hsh['total']}"
          expect(found_hsh['']).to eq(0), "expected list of results to have #{qty} successes but found #{found_hsh['ok']}/#{found_hsh['total']}"
          expect(took).to be_within(ratio).of(secs), "expected to finish in #{secs}s with a range of #{ratio}s but finished in #{took}s"
        end
      end
    end
  end

end
