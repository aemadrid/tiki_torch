# -*- encoding: utf-8 -*-

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'tiki/torch'

lgr                = Logger.new(STDOUT).tap { |x| x.level = Logger::INFO }
Tiki::Torch.logger = lgr

lgr.info 'Starting ...'

lgr.info 'Setting url ...'
Tiki::Torch.config.connection_url = 'amqp://localhost:5672'
lgr.info 'Will colorize logs ...'
Tiki::Torch.config.colorized = true

lgr.info 'Defining consumer ...'
class MySingleConsumer

  include Tiki::Torch::Consumer

  consume 'tiki.consumer.single.events'
  # queue_name 'my_single_consumer'

  def process(event)
    debug ">>> ##{object_id} : class    : #{event.class.name}"
    info  ">>> ##{object_id} : payload  : (#{event.payload.class.name}) #{event.payload.to_yaml}"
    debug ">>> ##{object_id} : metadata : (#{event.metadata.class.name}) #{event.metadata.to_yaml}"
    debug ">>> ##{object_id} : delivery : (#{event.delivery.class.name}) #{event.delivery.to_yaml}"
    sleep 3
  end

end

lgr.info 'Running ...'
Tiki::Torch.run
lgr.info 'Start polling for events ...'
Tiki::Torch.event_broker.start_polling

key = MySingleConsumer.routing_keys.first
qty = (ARGV[0] || 3).to_i

qty.times do |nr|
  lgr.info "[#{nr}] Publishing message #1 ..."
  Tiki::Torch.publish_message key, a: 1, b: 2, nr: nr
  lgr.info "[#{nr}] Publishing message #2 ..."
  Tiki::Torch.publish_message key, a: 3, b: 4, nr: nr
  lgr.info "[#{nr}] Publishing message #3 ..."
  Tiki::Torch.publish_message key, a: 5, b: 6, nr: nr
end

lgr.info 'Waiting for a moment ...'
sleep 10

lgr.info 'Shutting down ...'
Tiki::Torch.shutdown

lgr.info 'Done!'
exit
