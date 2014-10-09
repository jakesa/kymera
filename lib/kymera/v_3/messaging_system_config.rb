require 'ffi-rzmq'

module Kymera
  class MessageSystemConfig

    #returns the ZMQ context. If one is not already instantiated, one will be created and returned
    def self.context
      @context ||= ZMQ::Context.new
    end


  end
end
