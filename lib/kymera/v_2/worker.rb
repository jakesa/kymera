#require_relative 'socket_controller'
require 'ffi-rzmq'
require_relative 'platform_utils'
require 'json'

module Kymera

  class Worker
    #include Kymera::SocketController

    #attr_accessor :pull_socket, :push_socket, :socket_context, :pull_thread

    def initialize(incoming_address, out_going_address, context)
      puts "Worker Starting up..."
      @socket_context = context
      @incoming_address = incoming_address
      @out_going_address = out_going_address
      puts "Connecting to pull socket.."
      @pull_socket = create_pull_socket(@socket_context, @incoming_address)
      puts "Connecting to push socket.."
      @push_socket = create_push_socket(@socket_context, @out_going_address)
      @close = false
      puts "Worker Ready..."
    end

    def register_worker
      #TODO: registration logic to be put here later
    end

    def start_listening

        #puts "Server Started..."
        #@socket_context = ZMQ::Context.new(1)
        #puts "Connecting to push socket.."
        #@push_socket  = @socket_context.socket(ZMQ::PUSH)
        #error_check(@push_socket.setsockopt(ZMQ::LINGER, 1))
        #error_check(@push_socket.bind(@out_going_address))

        #puts "Connecting to pull socket.."
        #@pull_socket = @socket_context.socket(ZMQ::PULL)
        #error_check(@pull_socket.setsockopt(ZMQ::LINGER, 1))
        #error_check(@pull_socket.connect(@incoming_address))

        trap ("INT") do
          puts "Received interrupt, closing pull socket.."
          error_check(@pull_socket.close)
          puts "Closing push socket.."
          error_check(@push_socket.close)
          @close = true
          #puts "Closing context.."
          #error_check(@socket_context.terminate)
        end

        puts "waiting for messages.."
        loop do
          data = ''
          if @close
            puts "Worker shutdown."
            exit
          end
          unless @pull_socket.recv_string(data, ZMQ::DONTWAIT) == -1
            $stdout << "Received message: #{data}\n"
            process_work(@push_socket, data)
            #error_check(@push_socket.send_string("I did something with #{data}"))
            $stdout << "Replied to message\n"
          end
          #STDOUT.print @pull_socket.recv_string(data, 1)
          #@pull_socket.recv_string(data)
          #process_work(@push_socket, data)

        end
      #}.join

      #@socket_context.terminate
    end

    #def close
    #  #puts "killing thread...."
    #  #@pull_thread.kill
    #  #puts "Thread killed"
    #  error_check(close_socket(@pull_socket))
    #  error_check(close_socket(@push_socket))
    #  puts "Sockets closed"
    #  #close_context(@socket_context)
    #end

    private

    def process_work(socket, data)
      #do something
      #sleep 2
      puts JSON.parse(data)
      error_check(socket.send_string("I did something with #{data}"))
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