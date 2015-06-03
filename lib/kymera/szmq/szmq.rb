require 'ffi-rzmq'

module Kymera
  class SZMQ

    def initialize()
      SZMQ.context

    end

    def self.context
      @context ||= ZMQ::Context.new
    end

    #returns a SSocket object
    def socket(address, type)
      SSocket.new(address, type)
    end

    #Takes two SSocket objects. One representing the client and other representing the worker. Upon receiving a INT command (ctrl + c), the proxy still be shut down
    #and the frontend and backend sockets will be closed
    def start_proxy(frontend_socket, backend_socket)

      trap ("INT") do
        puts "\nStopping proxy..."
        frontend_socket.close
        backend_socket.close
        @close = true
      end

      frontend_socket.bind
      backend_socket.bind

      ZMQ::Device.new(frontend_socket.send(:get_socket), backend_socket.send(:get_socket))
      #ZMQ::Device.new(backend_socket.send(:get_socket), frontend_socket.send(:get_socket))

      #while !@close do
      #  text = "\r"
      #  text << "Online"
      #  space = " "
      #  0.upto(2) do
      #    STDOUT.print text
      #    sleep 0.5
      #    STDOUT.print "\r#{space * (text.length - 1)}"
      #    sleep 0.5
      #  end
      #end
    end

    def start_pub_sub_proxy(front_end, back_end, capture = nil)
      trap ("INT") do
        puts "\nStopping proxy..."
        front_end.close
        back_end.close
        @close = true
      end

      front_end.bind
      back_end.bind

      if capture.nil?
        p "No capture"
        ZMQ::Device.new(front_end.send(:get_socket), back_end.send(:get_socket))
      else
        p "Capture"
        capture.bind
        ZMQ::Device.new(front_end.send(:get_socket), back_end.send(:get_socket), capture.send(:get_socket))
      end


    end


    private

    def error_check(rc)
      if ZMQ::Util.resultcode_ok?(rc)
        false
      else
        STDERR.puts "Operation failed, [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
        caller(1).each { |callstack| STDERR.puts(callstack)}
        raise SystemExit
      end
    end
  end

  class SSocket

    def initialize(address, type)
      @socket_types = %w(request reply dealer router pub sub push pull xpub xsub)
      @context = SZMQ.context
      @address = address
      @socket_type_string = type
      @socket_type = get_socket_type(type)
      if @socket_types.include?(type.downcase)
        @socket = @context.socket(@socket_type)
        #for some reason if the socket is a push socket the linger option is causing the message not to get sent
        @socket.setsockopt(ZMQ::LINGER, 0) unless @socket_type_string == 'push'
      else
        raise "#{type} is not a valid socket type"
      end
    end

    def bind(address = @address)
      if address.nil?
        raise "An address must be set or passed"
      end
      error_check(@socket.bind(address))
    end

    def connect(address = @address)
      if address.nil?
        raise "An address must be set or passed"
      end
      error_check(@socket.connect(address))
    end

    def subscribe(channels, &block)
      raise "This socket is not of type SUB and cannot subscribe to a channel" unless @socket_type_string == 'sub'
      if channels.is_a? String
        #Debug code
        #puts "Subscribing to #{channels}"
        error_check(@socket.setsockopt(ZMQ::SUBSCRIBE, channels))
      elsif channels.is_a? Array
        channels.each do |channel|
          #debug code
          #puts "Subscribing to #{channel}"
          error_check(@socket.setsockopt(ZMQ::SUBSCRIBE, channel))
        end
      end
      connect
      channel = ''
      message = ''
      loop do
        @socket.recv_string(channel)
        @socket.recv_string(message)
        if block_given?
          yield(channel, message)
        else
          [channel, message]
        end
      end
    end

    def publish_message(channel, message)
      raise 'this socket is not of type PUB and cannot publish a message' unless @socket_type_string == 'pub'
      @socket.send_string(channel, ZMQ::SNDMORE)
      @socket.send_string(message)
    end

    def close
      error_check(@socket.close)
    end

    def send_message(message)
      trap ("INT") do
        puts "Received interrupt..."
        @socket.close
      end
      if @socket_type == ZMQ::REQ
        @socket.send_string(message)
        reply = ''
        @socket.recv_string(reply)
        reply
        #end
      else
        @socket.send_string(message)
        nil
      end
    end

    #This method listens for messages coming in and then processes them will the block passed into the method. If no block is passed, messages will be received but
    #will then be dropped on the floor. If the socket is of type REP and no block is given, the receive method will reply with "0" indicating that the message was received
    #currently, the result of the block is sent back as a reply for REP sockets.  This may change later
    #TODO - Currently, the send_string method is causing the interupt to be delayed until the next message is received. need to find a way to fix this
    #TODO - add support for SUB sockets
    def receive(&block)

      trap ("INT") do
        puts "Received interrupt..."
        @close = true
      end
      received_message = ''

      if @socket_type == ZMQ::PULL
        loop do
          break if @close
          @socket.recv_string(received_message)
          if block_given?
            yield(received_message)
          end
        end

      elsif @socket_type == ZMQ::REP
        reply_message = ''
        loop do
          break if @close
          unless @socket.recv_string(received_message) == -1
            @socket.recv_string(received_message)
            if block_given?
              reply_message = yield(received_message)
            else
              reply_message = "0"
            end
          end
          @socket.send_string(reply_message)
        end
      else
        raise "Socket type of #{@socket_type_string} does not receive messages"
      end
    end


    private

    def error_check(rc)
      if ZMQ::Util.resultcode_ok?(rc)
        false
      else
        STDERR.puts "Operation failed, [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
        caller(1).each { |callstack| STDERR.puts(callstack)}
        raise SystemExit
      end
    end

    def get_socket
      @socket
    end

    def get_socket_type(type)
      case type
        when 'request'
          ZMQ::REQ
        when 'reply'
          ZMQ::REP
        when 'dealer'
          ZMQ::DEALER
        when 'router'
          ZMQ::ROUTER
        when 'pub'
          ZMQ::PUB
        when 'sub'
          ZMQ::SUB
        when 'push'
          ZMQ::PUSH
        when 'pull'
          ZMQ::PULL
        when 'xpub'
          ZMQ::XPUB
        when 'xsub'
          ZMQ::XSUB
        else
          nil
      end
    end

  end
end

