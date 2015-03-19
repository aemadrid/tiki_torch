# -*- encoding: utf-8 -*-

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'tiki/torch'

lgr = Logger.new(STDOUT).tap { |x| x.level = Logger::INFO }
# Tiki::Torch.logger = lgr

lgr.info 'Starting ...'

lgr.info 'Setting url ...'
Tiki::Torch.config.nsqd = 'localhost:4150'
lgr.info 'Will colorize logs ...'
Tiki::Torch.config.colorized = true

lgr.info 'Defining consumer ...'
class MySingleConsumer

  include Tiki::Torch::Consumer

  topic 'single.events'
  # channel 'my_single_consumer'

  def process
    debug ">>> ##{object_id} : class      : #{event.class.name}"
    info  ">>> ##{object_id} : payload    : (#{event.payload.class.name}) #{event.payload.to_yaml}"
    debug ">>> ##{object_id} : properties : (#{event.properties.class.name}) #{event.properties.to_yaml}"
    # debug ">>> ##{object_id} : message    : (#{event.message.class.name}) #{event.message.to_yaml}"
  end

end

lgr.info 'Running ...'
Tiki::Torch.run
lgr.info 'Start polling for events ...'
Tiki::Torch.start_polling

key = MySingleConsumer.topic
qty = (ARGV[0] || 1).to_i

qty.times do |nr|
  lgr.info "[#{nr}] Publishing message #1 to [#{key}] ..."
  Tiki::Torch.publish key, a: 1, b: 2, nr: nr
  lgr.info "[#{nr}] Publishing message #2 to [#{key}] ..."
  Tiki::Torch.publish key, a: 3, b: 4, nr: nr
  lgr.info "[#{nr}] Publishing message #3 to [#{key}] ..."
  Tiki::Torch.publish key, a: 5, b: 6, nr: nr
end

lgr.info 'Waiting for a moment ...'
sleep 2

lgr.info 'Some stats ...'
lgr.info "Tiki::Torch.event_broker : stats : #{Tiki::Torch.event_broker.stats_hash.to_yaml}"
lgr.info "MySingleConsumer : stats : #{MySingleConsumer.stats_hash.to_yaml}"

lgr.info 'Shutting down ...'
Tiki::Torch.shutdown

lgr.info 'Done!'
exit
