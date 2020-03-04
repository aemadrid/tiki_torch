module Tiki
  module Torch
    module Publishing
      describe Retries, :fast do

        let(:topic_name){ "cheese" }
        # let(:full_topic_name){ "fantastic-cheese-events" }
        let(:payload) { {cheese: {type: "swiss"}} }
        let(:props) { {texture: "holey", prefix: "fantastic"} }
        let(:event) { Message.new(payload, props, "yaml") }

        describe "retries messages on a schedule", :focus do

        end

      end
    end
  end
end

system 'clear'
@count_max = 5
@interval = 0.25
task = Concurrent::TimerTask.new(execution_interval: @interval) do |t|
  @count ||= 1
  @count += 1
  puts "> @count : #{@count}"
  if @count >= @count_max
    @count = 0
    t.shutdown
    puts "> done!"
  end
end; task.execute; nil
