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

lgr.info 'Running ...'
Tiki::Torch.run

key = 'tiki.consumer.multiple.events'
qty = (ARGV[0] || 10).to_i

qty.times do |nr|
  lgr.info "[#{nr}] Publishing message #1 ..."
  Tiki::Torch.publish_message key, a: 1, b: 2, nr: nr
  lgr.info "[#{nr}] Publishing message #2 ..."
  Tiki::Torch.publish_message key, a: 3, b: 4, nr: nr
  lgr.info "[#{nr}] Publishing message #3 ..."
  Tiki::Torch.publish_message key, a: 5, b: 6, nr: nr
end

lgr.info 'Shutting down ...'
Tiki::Torch.shutdown

lgr.info 'Done!'
exit
