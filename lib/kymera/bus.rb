require_relative 'szmq/szmq'
require 'json'

module Kymera

  class Bus

    def initialize
      @config = Kymera::Config.new
      @zmq = Kymera::SZMQ.new
      # @incoming_socket = @zmq.socket("tcp://*:7000", 'xsub')
      @incoming_socket = @zmq.socket("tcp://*:#{@config.bus["pub_port"]}", 'xsub')
      @outgoing_socket = @zmq.socket("tcp://*:#{@config.bus["sub_port"]}", 'xpub')
      # @outgoing_socket = @zmq.socket("tcp://*:7001", 'xpub')
    end

    def start_bus(logging = false)
      puts @config.bus["pub_port"]
      puts @config.bus["sub_port"]
      if logging
        puts "Results bus started..."
        puts "Listening for stuff"
        puts "Logging is turned on"
        logging_socket = @zmq.socket("tcp://*:7010", 'push')
        t = Thread.new {@zmq.start_pub_sub_proxy(@incoming_socket, @outgoing_socket, logging_socket)}
        output_socket = @zmq.socket("tcp://127.0.0.1:7010", 'pull')
        output_socket.connect
        output_socket.receive {|message|
          puts message
        }
        t.join
      else
        puts "Results bus started..."
        puts "Listening for stuff"
        @zmq.start_pub_sub_proxy(@incoming_socket, @outgoing_socket)
      end
    end




  end


end