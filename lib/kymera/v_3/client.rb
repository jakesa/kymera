require 'ffi-rzmq'

module Kymera

  class Client

    def initialize(broker_addr)
      @context = Kymera::MessageSystem.context
      @socket = @context.socket(ZMQ::REQ)
      @socket.setsockopt(ZMQ::LINGER, 0)
      MessageSystem.error_check(@socket.connect(broker_addr))
    end

    def send_message(message)
      @socket.send_string(message)
      reply = ''
      #This is the handle for getting the reply back
      unless @socket.recv_string(reply) == -1
        @socket.recv_string(reply)
        puts reply
      end

    end

  end


end