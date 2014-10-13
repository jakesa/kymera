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

  #Takes two SSocket objects. One representing the client and other representing the worker
  def start_proxy(frontend_socket, backend_socket)
    ZMQ::Device.new(frontend_socket.send(:get_socket), backend_socket.send(:get_socket))
  end


end

class SSocket

  @socket_types = %w(request reply dealer router pub sub push pull)

  def initialize(address, type)
    @context = SZMQ.context
    @address = address
    if @socket_types.include?(type.downcase)
      @socket = @context.socket(ZMQ::get_socket_type(type))
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

  def send(message, wait_for_reply = true)
    if wait_for_reply
      @socket.send_string(message)
      reply = ''
      @socket.recv_string(reply)
      reply
    else
      @socket.send_string(message, ZMQ::DONTWAIT)
      nil
    end
  end

  #This is a blocking method call and will continue waiting for messages unless it receives and INT command (ctrl + c). reply is set to true by default and will send a reply to the sender with
  #the outcome of the block passed in.  If no block is passed in, and reply is set to true, the reply will send "0"
  def receive(reply = true, &block)
    trap ("INT") do
      puts "Received interrupt..."
      @close = true
    end

    if reply
      loop do
        break if @close
        unless @socket.recv_string(reply) == -1
          reply_message = ''
          @socket.recv_string(reply)
          if block_given?
            reply_message = yield(reply)
          else
            reply_message = "0"
          end
          @socket.send_string(reply_message)
        end
      end
    elsif !reply
      loop do
        break if @close
        unless @socket.recv_string(reply) == -1
          @socket.recv_string(reply)
          if block_given?
            yield(reply)
          end
        end
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

  def get_socket
    @socket
  end

  def get_socket_type(type)
    case type
      when request
        REQ
      when reply
        REP
      when dealer
        DEALER
      when router
        ROUTER
      when pub
        PUB
      when sub
        SUB
      when push
        PUSH
      when pull
        PULL
      else
        nil
    end
  end

end
