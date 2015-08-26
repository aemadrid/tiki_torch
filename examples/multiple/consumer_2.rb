lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'tiki/torch'

lgr                = Logger.new(STDOUT).tap { |x| x.level = Logger::INFO }
Tiki::Torch.logger = lgr

lgr.info 'Starting ...'

lgr.info 'Defining consumer ...'
class MySecondConsumer < Tiki::Torch::Consumer

  consumes 'multiple.events', channel: 'my_second_consumer'

  def process
    debug ">>> ##{object_id} : class    : #{event.class.name}"
    info ">>> ##{object_id} : payload  : (#{event.payload.class.name}) #{event.payload.to_yaml}"
    debug ">>> ##{object_id} : metadata : (#{event.metadata.class.name}) #{event.metadata.to_yaml}"
    debug ">>> ##{object_id} : delivery : (#{event.delivery.class.name}) #{event.delivery.to_yaml}"
  end

end

lgr.info 'Start polling for events ...'
Tiki::Torch.start_polling

lgr.info 'Waiting for a moment ...'
sleep 30

lgr.info 'Some stats ...'
lgr.info "MyFirstConsumer : #{MySecondConsumer.stats.to_hash.to_yaml}"

lgr.info 'Shutting down ...'
Tiki::Torch.shutdown

lgr.info 'Done!'
exit
