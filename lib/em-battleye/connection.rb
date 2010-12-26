# encoding: ASCII-8BIT

require 'eventmachine'
require 'socket'
require 'thread'
require 'strscan'
require 'zlib'

module EventMachine
  module BattlEye
    class Connection < EventMachine::Connection
      include EventMachine::Deferrable

      attr :state
      attr_accessor :host, :port, :password
      attr_reader :sequence
      
      HEADER = "\x42\x45" # BE
      
      def post_init
        @packets = [ ]
        @blocks = { }
        @sequence = 0
        @state = :disconnected
      end

      def onlogin(&blk);    @onlogin = blk;   end
      def onmessage(&blk);  @onmessage = blk; end

      def receive_data dgm
        @port, @host = Socket.unpack_sockaddr_in(self.get_peername)

        s = StringScanner.new(dgm)

        a = Regexp.new("BE(....)\xff", Regexp::MULTILINE, 'n')
        if !s.scan(a) then
          close_connection
          set_deferred_status(:failed, self, "Invalid packet header")
        end

        checksum = s[1].unpack("I")[0]
        if checksum != Zlib.crc32("\xff" + s.rest) then
          close_connection
          set_deferred_status(:failed, self, "Corrupt data recieved")
        end

        case s.get_byte
        when "\x00"
          status = s.get_byte
          case status 
          when "\x00"
            close_connection
            set_deferred_status(:failed, self, "Login Failed")
          when "\x01"
            @state = :logged_in          
            @onlogin.call
            set_deferred_status(:succeeded, self, "Logged In")
          end
          
        when "\x01"
          sequence = s.get_byte
          reply = s.rest
          
          val = sequence.unpack("c")[0]

          if !@blocks[val].nil?
            @blocks[val].call(reply)
            @blocks[val] = nil
          end
        when "\x02"
          sequence = s.get_byte
          send_request :server, sequence

          reply = s.rest
          if !@onmessage.nil?
            @onmessage.call(reply)
          end

        else
          close_connection
          set_deferred_status(:failed, self, "Odd message type recieved")
        end
      end  

      def timeout
        if @state == :logged_in then
          send_request :command, ""
          BeRcon.add_timeout(self, 30)
        end
      end
      
      def send_request(type, data, block = nil)
        data = case type
               when :login
                 "\xff\x00" + data
               when :command
                 @sequence = @sequence % 256
                 msg = "\xff\x01" + [ @sequence ].pack("c") + data

                 if !block.nil?
                   @blocks[sequence] = block
                 end

                 @sequence += 1
                 msg 
               when :server
                 "\xff\x02" + data
               end

        header = HEADER + [ Zlib.crc32(data) ].pack("I")
        msg = header + data
        # p [ :send,  msg ]
        send_datagram msg, @host, @port
      end

      def login
        send_request :login, @password
      end

      def command(msg, &block)
        send_request :command, msg, block
      end
    end
  end
end
