# -*- encoding: utf-8 -*-

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'tiki/torch'

logger = Tiki::Torch.logger

logger.info 'Starting ...'

logger.info 'Defining consumer ...'
class MyConsumer

  include Tiki::Torch::Consumer

  consume 'tiki.great.things.to.come'
  queue_name 'tiki.my.great.queue'

  def process(event)
    warn ">>> ##{object_id} : class      : #{event.class.name}"
    warn ">>> ##{object_id} : payload    : (#{event.payload.class.name}) #{event.payload.to_yaml}"
    warn ">>> ##{object_id} : metadata   : (#{event.payload.class.name}) #{event.metadata.to_yaml}"
    warn ">>> ##{object_id} : delivery   : (#{event.payload.class.name}) #{event.delivery.to_yaml}"
    warn ">>> ##{object_id} : properties : (#{event.payload.class.name}) #{event.properties.inspect}"
  end

end

MyConsumer.debug_var :queue_name, MyConsumer.queue_name
MyConsumer.debug_var :routing_keys, MyConsumer.routing_keys

logger.info 'Running ...'
Tiki::Torch.run

logger.info 'Publishing message #1 ...'
Tiki::Torch.publish_message 'tiki.great.things.to.come', a: 1, b: 2
logger.info 'Publishing message #2 ...'
Tiki::Torch.publish_message 'tiki.great.things.to.come', {a: 3, b: 4}, {c: 'a'}
logger.info 'Publishing message #3 ...'
Tiki::Torch.publish_message 'tiki.great.things.to.come', {a: 5, b: 6}, {c: 'b'}

logger.info 'Waiting for a moment ...'
sleep 2

logger.info 'Shutting down ...'
Tiki::Torch.shutdown

logger.info 'Done!'
exit

Celluloid::SupervisionGroup