require 'pathname'
require 'set'
require 'thread_safe'
require 'tiki/torch/version'
require 'tiki/torch/core_ext'

module Tiki
  module Torch

    extend self

    def root
      ::Pathname.new File.expand_path('../../', __FILE__)
    end

    def processes
      @processes ||= Set.new
    end

    def shutdown
      processes.each do |x|
        logger.debug " shutting down #{x} ".center(90, '=')
        send(x).shutdown
      end
      until processes.all?{|x| send(x).stopped? }
        logger.debug 'waiting for all to stop ...'
        sleep 0.25
      end
      logger.debug 'all shut down ...'
    end

    at_exit { shutdown }

  end
end

require 'tiki/torch/logging'
require 'tiki/torch/config'

require 'tiki/torch/transcoder'
require 'tiki/torch/transcoders/json'

require 'tiki/torch/stats'
require 'tiki/torch/consumer_poller'
require 'tiki/torch/consumers/activerecord'
require 'tiki/torch/consumers/back_off'
require 'tiki/torch/consumer'
require 'tiki/torch/event'
require 'tiki/torch/thread_pool'
require 'tiki/torch/consumer_broker'

require 'tiki/torch/publisher'
