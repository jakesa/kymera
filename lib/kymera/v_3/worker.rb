require 'ffi-rzmq'

module Kymera

  class Worker

    def initialize(broker_addr, results_addr, config_addr)
      @context = Kymera::MessageSystem.context
      @socket = @context.socket(ZMQ::REP)
      @socket.setsockopt(ZMQ::LINGER, 0)
      MessageSystem.error_check(@socket.connect(broker_addr))
      @results_socket = @context.socket(ZMQ::REQ)
      @results_socket.setsockopt(ZMQ::LINGER, 0)
      MessageSystem.error_check(@results_socket.connect(results_addr))
      @config_socket = @context.socket(ZMQ::REP)
      @config_socket.setsockopt(ZMQ::LINGER, 0)
      MessageSystem.error_check(@config_socket.connect(config_addr))

    end

    def listen
      trap ("INT") do
        puts "Received interrupt, closing all sockets.."
        @socket.close
        @results_socket.close
        @config_socket.close
        @close = true
      end

      reply = ''
      loop do
        break if @close
        unless @socket.recv_string(reply) == -1
          @socket.recv_string(reply)
          #This is a stub for now. a message processing call will be made here when that functionality is implemented
          puts "received string #{reply}"
          #this is the reply signaling that the process is done.
          send_results(reply)
          @socket.send_string("Ready")
        end
      end
    end

    def send_results(results)
      reply = ''
      loop do
        break if @close
        unless @results_socket.recv_string(reply) == -1
          @results_socket.send_string(results)
          @results_socket.recv_string(reply)
          puts reply
        end

      end
    end

  end
end