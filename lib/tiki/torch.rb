require 'pathname'
require 'tiki/torch/version'
require 'tiki/torch/core_ext'

module Tiki
  module Torch

    extend self

    def root
      ::Pathname.new File.expand_path('../../', __FILE__)
    end

  end
end

require 'tiki/torch/logging'
require 'tiki/torch/config'
require 'tiki/torch/consumer'
require 'tiki/torch/event'
require 'tiki/torch/event_broker'
require 'tiki/torch/event_processor'
require 'tiki/torch/supervision_group'
require 'tiki/torch/publisher'
