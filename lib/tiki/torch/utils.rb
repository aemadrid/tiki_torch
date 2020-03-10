module Tiki
  module Torch
    class Utils

      class << self

        def dhms(seconds)
          time = seconds.to_s.to_f

          secs = time % 60
          time = time.to_i / 60

          mins = time % 60
          time /= 60

          hours = time % 24
          time  /= 24

          days = time

          str = ''
          str << "#{days}d " if days > 0
          str << "#{hours}h " if hours > 0
          str << "#{mins}m " if mins > 0
          str << (secs > 1.0 ? "#{'%.0f' % secs}s" : "#{'%.2f' % secs}s")

          str
        end

        def time_taken(start_time, end_time = Time.now)
          dhms end_time - start_time
        end

        def time_expected(started, done, total)
          time_taken = now - started
          left       = total - done
          dhms time_taken / done * left
        end

        def wait_for(secs, &blk)
          end_time = Time.now + secs

          while Time.now < end_time
            if block_given?
              break if blk.call
            end
            sleep 0.1
          end
        end

        def host
          @host ||= Socket.gethostname
        end

        def random_name(syllables = 4, sep = 4)
          consonants = %w{ b c d f g j k l m n p r s t z }
          vowels     = %w{ a e i o u }
          list       = syllables.times.map { consonants.sample + vowels.sample }.join.split('')
          list.each_slice(sep).map { |x| x.join }.join('-')
        end

        def random_closed_port(start = 3000, limit = 1000)
          port, closed = nil, false
          until closed
            port   = start + rand(limit) + 1
            closed = !port_open?(port)
          end
          port
        end

        def port_open?(port, ip = '127.0.0.1', seconds = 0.5)
          Timeout::timeout(seconds) do
            begin
              TCPSocket.new(ip, port).close
              true
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              return false
            end
          end
        rescue Timeout::Error
          return false
        end

        def simplified_name(str)
          str.dup.gsub(/[^\w]/, '')
        end

      end

    end
  end
end