require_relative 'szmq/szmq'
require 'json'

module Kymera

  class ResultsBus

    def initialize(incoming_address, outgoing_address)
      @zmq = Kymera::SZMQ.new
      @incoming_socket = @zmq.socket(incoming_address, 'xsub')
      @outgoing_socket = @zmq.socket(outgoing_address, 'xpub')
    end

    def start_bus
      puts "Results bus started..."
      @zmq.start_pub_sub_proxy(@incoming_socket, @outgoing_socket)
    end




  end


end