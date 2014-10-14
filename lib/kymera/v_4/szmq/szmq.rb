require 'ffi-rzmq'

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

    Thread.new{ZMQ::Device.new(backend_socket.send(:get_socket), frontend_socket.send(:get_socket))}

    while !@close do
      text = "\r"
      text << "Online"
      space = " "
      0.upto(2) do
        STDOUT.print text
        sleep 0.5
        STDOUT.print "\r#{space * (text.length - 1)}"
        sleep 0.5
      end
    end
  end


  private

  def error_check(rc)
    if ZMQ::Util.resultcode_ok?(rc)
      false
    else
      STDERR.puts "Operation failed, [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
      caller(1).each { |callstack| STDERR.puts(callstack)}
    end
  end
end

class SSocket

  def initialize(address, type)
    @socket_types = %w(request reply dealer router pub sub push pull)
    @context = SZMQ.context
    @address = address
    @socket_type_string = type
    @socket_type = get_socket_type(type)
    if @socket_types.include?(type.downcase)
      @socket = @context.socket(@socket_type)
      @socket.setsockopt(ZMQ::LINGER, 0)
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
      #unless @socket.recv_string(reply) == -1
        @socket.recv_string(reply)
        reply
      #end
    else
      @socket.send_string(message, ZMQ::DONTWAIT)
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
      else
        nil
    end
  end

end
