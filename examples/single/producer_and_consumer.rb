lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'tiki/torch'

lgr       = Tiki::Torch.logger
lgr.level = Logger::INFO

lgr.info 'Starting ...'

lkd = ENV['NSLOOKUPD_ADDRESS']
nsd = ENV['NSQD_ADDRESS']

Tiki::Torch.configure do |c|
  if lkd
    c.nsqlookupd = lkd
  elsif nsd
    c.nsqd = nsd
  else
    c.nsqd = 'localhost:4150'
  end
end

lgr.info 'Defining consumer ...'
class MySingleConsumer < Tiki::Torch::Consumer

  consumes 'single.events'

  def process
    id_str = "##{object_id} : ##{Thread.current.object_id}"
    debug " [ START : #{id_str} ] ".center(90, '=')

    debug "#{id_str} : class      : #{event.class.name}"
    info "#{id_str} : payload    : (#{event.payload.class.name}) #{event.payload.inspect}"
    debug "#{id_str} : properties : (#{event.properties.class.name}) #{event.properties.inspect}"

    sleep_secs = (ARGV[2] || 0).to_i
    if sleep_secs > 0
      max_time = Time.now + sleep_secs + rand(3)
      while (now = Time.now) < max_time
        debug "#{id_str} : waiting for #{'%.2f secs' % (max_time - now)} ..."
        sleep 0.5
      end
      debug "#{id_str} : done waiting ..."
    end

    debug " [ END : #{id_str} ] ".center(90, '-')
  end

end

lgr.info 'Start polling for events ...'
Tiki::Torch.start_polling

key = MySingleConsumer.topic
qty = (ARGV[0] || 10).to_i

qty.times do |nr|
  lgr.info "[#{nr}] Publishing message #1 to [#{key}] ..."
  Tiki::Torch.publish key, a: 1, b: 2, nr: nr
end

lgr.info 'Waiting for a moment ...'
sleep (ARGV[1] || 2).to_i

lgr.info 'Shutting down ...'
Tiki::Torch.shutdown

lgr.info 'Some stats ...'
lgr.info "MySingleConsumer : stats : #{MySingleConsumer.stats.to_hash.to_yaml}"

lgr.info 'Done!'
exit
