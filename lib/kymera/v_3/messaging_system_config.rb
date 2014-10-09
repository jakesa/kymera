require 'ffi-rzmq'

module Kymera
  class MessageSystem

    #returns the ZMQ context. If one is not already instantiated, one will be created and returned
    def self.context
      @context ||= ZMQ::Context.new
    end

    def self.error_check(rc)
      if ZMQ::Util.resultcode_ok?(rc)
        false
      else
        STDERR.puts "Operation failed, [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
        caller(1).each { |callstack| STDERR.puts(callstack)}
      end
    end



  end
end
