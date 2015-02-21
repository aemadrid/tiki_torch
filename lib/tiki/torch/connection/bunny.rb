# -*- encoding: utf-8 -*-

begin
  require 'bunny'
  TIKI_TORCH_BUNNY_LOADED = true
rescue LoadError
  TIKI_TORCH_BUNNY_LOADED = false
end

module Tiki
  module Torch
    class BunnyConnection < Connection



    end
  end
end if TIKI_TORCH_BUNNY_LOADED