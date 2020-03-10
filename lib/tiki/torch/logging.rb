# frozen_string_literal: true

module Tiki
  module Torch
    module Logging
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def logger
          Torch.logger
        end

        def debug_var(var_name, var, meth = :inspect, level = :debug)
          msg   = var.nil? ? 'NIL' : var.send(meth)
          msg   = msg[0..-2] if msg[-1, 1] == "\n"
          klass = var.is_a?(Class) ? var.name : var.class.name
          logger.send level, "#{log_prefix} #{var_name} : (#{klass}:#{var.object_id}) #{msg}"
        end

        def log(string, type = :debug)
          msg = "#{log_prefix} #{string}"
          logger.send type, msg
        end

        def debug(string)
          log string, :debug
        end

        def info(string)
          log string, :info
        end

        def warn(string)
          log string, :warn
        end

        def error(string)
          log string, :error
        end

        def raise_errors=(value)
          @raise_errors = value
        end

        def raise_errors?
          !!@raise_errors
        end

        def backtrace_size=(value)
          @backtrace_size = value
        end

        def backtrace_size
          @backtrace_size || 5
        end

        def log_exception(e, extras = {})
          @exception_proc.call e, extras if @exception_proc
          if raise_errors?
            raise e
          else
            error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
          end
        end

        def on_exception(action = :set, &blk)
          case action
          when :clear
            @exception_proc = nil
          when :set
            raise 'Missing block' unless block_given?
            @exception_proc = blk
          end
        end

        def log_prefix
          length    = 60
          prefix    = name
          _, _, lbl = log_prefix_labels
          prefix    += ".#{lbl}" if lbl
          prefix    = prefix.rjust(length, ' ')[-length, length]
          prefix    += format(' T%s', Thread.current.object_id.to_s[-4..-1]) if ENV['LOG_THREAD_ID'] == 'true'
          prefix    += format(' C%02i:%02i', run_thread_count, thread_count) if ENV['LOG_THREAD_COUNT'] == 'true'
          prefix    += ' | '
          prefix
        end

        def run_thread_count
          Thread.list.select { |thread| thread.status == 'run' }.count
        end

        def thread_count
          Thread.list.count
        end

        def log_prefix_labels
          caller
            .reject { |x| x.index(__FILE__) }
            .map { |x| x =~ /(.*):(.*):in `(.*)'/ ? [Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)] : nil }
            .first
        end
      end

      def debug(string)
        self.class.debug string
      end

      def debug_var(name, var, meth = :inspect, level = :debug)
        self.class.debug_var name, var, meth, level
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

      def log_exception(e, extras = {})
        self.class.log_exception e, extras
      end
    end

    extend self

    attr_accessor :logger

    self.logger = Logger.new(STDOUT).tap { |x| x.level = Logger::INFO } if logger.nil?
  end
end
