# -*- encoding: utf-8 -*-

require 'colorize'
require 'yaml'

module Tiki
  module Torch
    module Logging

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        def debug(string)
          Tiki::Torch.logger.debug "#{log_prefix} #{string}".blue
        end

        def debug_var(var_name, var, meth = :inspect)
          msg   = var.nil? ? 'NIL' : var.send(meth)
          msg   = msg[0..-2] if msg[-1, 1] == "\n"
          klass = var.is_a?(Class) ? var.name : var.class.name
          debug "#{var_name} : (#{klass}:#{var.object_id}) #{msg}"
        end

        def info(string)
          Tiki::Torch.logger.info "#{log_prefix} #{string}".cyan
        end

        def warn(string)
          Tiki::Torch.logger.warn "#{log_prefix} #{string}".yellow
        end

        def error(string)
          Tiki::Torch.logger.error "#{log_prefix} #{string}".red
        end

        def log_prefix
          "#{'%-35.35s' % name} | "
        end

      end

      def debug(string)
        self.class.debug string
      end

      def debug_var(name, var, meth = :inspect)
        self.class.debug_var name, var, meth
      end

      def info(string)
        self.class.info string
      end

      def warn(string)
        self.class.warn string
      end

      def error(string)
        self.class.error string
      end

    end
  end
end