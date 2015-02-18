# -*- encoding: utf-8 -*-

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'tiki/torch'

lgr = Tiki::Torch.logger

lgr.info 'Starting ...'

lgr.info 'Will poll for events ...'
Tiki::Torch.config.poll_for_events = true
lgr.info 'Will colorize logs ...'
Tiki::Torch.config.colorized = true

lgr.info 'Defining consumer ...'
class MyConsumer

  include Tiki::Torch::Consumer

  consume 'tiki.great.things.to.come'
  queue_name 'tiki.my.great.queue'

  def process(event)
    warn ">>> ##{object_id} : class    : #{event.class.name}"
    warn ">>> ##{object_id} : payload  : (#{event.payload.class.name}) #{event.payload.to_yaml}"
    warn ">>> ##{object_id} : metadata : (#{event.metadata.class.name}) #{event.metadata.to_yaml}"
    warn ">>> ##{object_id} : delivery : (#{event.delivery.class.name}) #{event.delivery.to_yaml}"
    warn ">>> ##{object_id} : headers  : (#{event.headers.class.name}) #{event.headers.inspect}"
  end

end

MyConsumer.debug_var :queue_name, MyConsumer.queue_name
MyConsumer.debug_var :routing_keys, MyConsumer.routing_keys

lgr.info 'Running ...'
Tiki::Torch.run

pl1  = { a: 1, b: 2 }
pl1h = { headers: {} }
pl2  = { a: 3, b: 4 }
pl2h = { headers: { c: 'a' } }
pl3  = { a: 5, b: 6 }
pl3h = { headers: { c: 'b' } }

lgr.info 'Publishing message #1 ...'
Tiki::Torch.publish 'tiki.great.things.to.come', pl1, pl1h
lgr.info 'Publishing message #2 ...'
Tiki::Torch.publish 'tiki.great.things.to.come', pl2, pl2h
lgr.info 'Publishing message #3 ...'
Tiki::Torch.publish 'tiki.great.things.to.come', pl3, pl3h

lgr.info 'Waiting for a moment ...'
sleep 2

lgr.info 'Shutting down ...'
Tiki::Torch.shutdown

lgr.info 'Done!'
exit
