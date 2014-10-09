require 'ffi-rzmq'

module Kymera

  class Worker

    def initialize(broker_addr)
      @context = Kymera::MessageSystem.context
      @socket = @context.socket(ZMQ::REP)
      @socket.setsockopt(ZMQ::LINGER, 0)
      MessageSystem.error_check(@socket.connect(broker_addr))
    end

    def listen
      #unless @socket.recv_string(data, ZMQ::DONTWAIT) == -1
      #end
      reply = ''
        @socket.recv_string(reply)
        puts "received string #{reply}"
        listen

    end

  end


end