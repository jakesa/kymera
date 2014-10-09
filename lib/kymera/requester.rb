require 'ffi-rzmq'

module Kymera


  class Requester


    def initialize(addr, num_connections)
      @context = ZMQ::Context.new(num_connections)
      @requester = @context.socket(ZMQ::REQ)
      @addr = addr
    end

    def connect
      @requester.connect(@addr)
    end

    def disconnect
      @requester.disconnect(@addr)
    end





  end




end