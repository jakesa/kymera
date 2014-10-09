require 'ffi-rzmq'

module Kymera

  module SocketController

    def create_context
      ZMQ::Context.new(1)
    end

    def create_push_socket(context, address)
      socket = context.socket(ZMQ::PUSH)
      error_check(socket.setsockopt(ZMQ::LINGER, 1))
      error_check(socket.bind(address))
      #ObjectSpace.define_finalizer(self, proc {socket.close})
      socket
    end

    def create_pull_socket(context, address)
      socket = context.socket(ZMQ::PULL)
      error_check(socket.setsockopt(ZMQ::LINGER, 1))
      error_check(socket.connect(address))
      #ObjectSpace.define_finalizer(self, proc {socket.close})
      socket
    end

    def close_socket(socket)
      socket.close
    end

    def close_context(context)
      context.terminate
    end


    def error_check(rc)
      if ZMQ::Util.resultcode_ok?(rc)
        false
      else
        STDERR.puts "Operation failed, [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
        caller(1).each { |callstack| STDERR.puts(callstack)}
      end
    end


  end


end