require_relative 'szmq/szmq'
require 'json'

module Kymera

  class ResultsBus

    def initialize
      config = Kymera::Config.new
      @zmq = Kymera::SZMQ.new
      # @incoming_socket = @zmq.socket("tcp://*:7000", 'xsub')
      @incoming_socket = @zmq.socket("tcp://*:#{config.result_bus["pub_port"]}", 'xsub')
      @outgoing_socket = @zmq.socket("tcp://*:#{config.result_bus["sub_port"]}", 'xpub')
      # @outgoing_socket = @zmq.socket("tcp://*:7001", 'xpub')
    end

    def start_bus
      puts "Results bus started..."
      puts "Listening for stuff"
      @zmq.start_pub_sub_proxy(@incoming_socket, @outgoing_socket)
    end




  end


end