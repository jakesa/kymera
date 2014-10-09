#require 'ffi-rzmq'
#require_relative 'socket_controller'
#module Kymera
#
#  class Client
#    include Kymera::SocketController
#
#    attr_accessor :tests, :push_socket, :pull_socket, :context
#
#    def initialize(tests, worker_address, results_address)
#      @context = create_context
#      @push_socket = create_push_socket(@context, worker_address)
#      @pull_socket = create_pull_socket(@context,results_address)
#      @tests = tests
#    end
#
#    def run_tests(_tests = tests )
#      _tests.each do |test|
#        puts "sending test"
#        error_check(push_socket.send_string(test))
#      end
#      i=0
#      until i == _tests.count do
#        result = ''
#        unless pull_socket.recv_string(result, ZMQ::DONTWAIT) == -1
#          puts result
#          i+=1
#        end
#
#      end
#
#      close
#    end
#
#    def close
#      error_check(close_socket(pull_socket))
#      error_check(close_socket(push_socket))
#      close_context(@context)
#    end
#
#  end
#
#
#
#
#end