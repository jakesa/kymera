require_relative 'szmq/szmq'
require 'json'


module Kymeara

  class RegistryNode

    def initialize(listening_port = 55211)
      @registry = Kymera::Registry.new
      @config = Kymera::Config.new
      @listen_thread = []
      @broker_address = config.registry["broker_address"]
      @listening_port = listening_port
    end

    def listen
      @listen_thread << Thread.new {
        context = Kymera::SZMQ.new
        context.socket("tcp://*:#{@listening_port}", 'request')
      }


    end




  end

end