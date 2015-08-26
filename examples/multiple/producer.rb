lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'tiki/torch'

lgr                = Logger.new(STDOUT).tap { |x| x.level = Logger::INFO }
Tiki::Torch.logger = lgr

lgr.info 'Starting ...'

key = 'multiple.events'
qty = (ARGV[0] || 10).to_i

qty.times do |nr|
  lgr.info "[#{nr}] Publishing message #1 ..."
  Tiki::Torch.publish key, a: 1, b: 2, nr: nr
  lgr.info "[#{nr}] Publishing message #2 ..."
  Tiki::Torch.publish key, a: 3, b: 4, nr: nr
  lgr.info "[#{nr}] Publishing message #3 ..."
  Tiki::Torch.publish key, a: 5, b: 6, nr: nr
end

lgr.info 'Shutting down ...'
Tiki::Torch.shutdown

lgr.info 'Done!'
exit
