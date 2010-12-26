# encoding: ASCII-8BIT
require 'eventmachine'
require 'socket'
require 'thread'
require 'strscan'
require 'zlib'

module EventMachine
  module BattlEye
    @@timeouts = [ ]
    @@initialized = false
    
    def self.add_timeout(c, timeout)
      @@timeouts.push [ Time.now + timeout, c ]
    end
    
    def self.remove_timeout(c)
      @@timeouts.delete_if { |t, conn| c == conn }
    end

    def self.process_timeouts
      time = Time.now
      @@timeouts.each { |k|
        if k[0] < time
          k[1].timeout
        end
      }
      @@timeouts.delete_if { |t, conn| t < time }

      EventMachine.add_timer(2) {
        self.process_timeouts
      }
    end

    
    def self.start
      EM.epoll
      current = Thread.current
      
      @@thread = Thread.new {
        EventMachine.run {
          current.wakeup
          
          trap("TERM") { stop }
          trap("INT") { stop }

          EventMachine.add_timer(1.0) { 
            self.process_timeouts
          }
        }
      }
      Thread.stop
    end    
    
    def self.stop
      puts "Terminating BattlEye Client"
      EventMachine.stop
    end
      

    def self.connect(host, port, password)
      connection = EM.open_datagram_socket("0.0.0.0", 0, EventMachine::BattlEye::Connection) { |c|
        c.host = host
        c.port = port
        c.password = password
        c.login
        
        add_timeout(c, 30)
      }    
      return connection
    end
  end
end
