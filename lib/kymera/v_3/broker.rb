require 'ffi-rzmq'

module Kymera

  attr_accessor :context, :front_end_socket, :back_end_socket

  class Broker

    def initialize
      @context = Kymera::MessageSystemConfig.context
      @test_queue = {}
      @config_queue = {}
      @result_queue = {}
    end

    def set_test_queue(client_addr, worker_addr)
      #get the front end socket
      puts "Setting up test front end"
      @test_queue[:front_end] = @context.socket(ZMQ::ROUTER)
      #bind the front end socket
      $stdout << "."
      error_check(@test_queue[:front_end].bind(client_addr))
      #get the back end socket
      puts "Setting up test back end"
      @test_queue[:back_end] = @context.socket(ZMQ::DEALER)
      $stdout << "."
      error_check(@test_queue[:back_end].bind(worker_addr))
      $stdout << "."
    end

    def set_confiq_queue(client_addr, worker_addr)
      @config_queue[:front_end] = @context.socket(ZMQ::ROUTER)
      error_check(@config_queue[:front_end].bind(client_addr))
      @config_queue[:back_end] = @context.socket(ZMQ::DEALER)
      error_check(@config_queue[:back_end].bind(worker_addr))
    end

    def set_result_queue(client_addr, worker_addr)
      @result_queue[:front_end] = @context.socket(ZMQ::ROUTER)
      error_check(@result_queue[:front_end].bind(client_addr))
      @result_queue[:back_end] = @context.socket(ZMQ::DEALER)
      error_check(@result_queue[:back_end].bind(worker_addr))
    end

    def start_broker
      threads = []
      @close = false
      puts "Starting broker.."
      trap ("INT") do
        puts "Received interrupt, closing all sockets.."

        @test_queue.each_value do |socket|
          error_check(socket.close)
        end

        @config_queue.each_value do |socket|
          error_check(socket.close)
        end

        @result_queue.each_value do |socket|
          error_check(socket.close)
        end
        @close = true
      end

      threads << Thread.new {
        unless @test_queue.empty?
          puts "Starting test queue.."
          test_proxy = ZMQ::Device.new(@test_queue[:front_end], @test_queue[:back_end])
          error_check(test_proxy)
        end
      }

      threads << Thread.new {
        unless @config_queue.empty?
          confiq_proxy = ZMQ::Device.new(@config_queue[:front_end], @config_queue[:back_end])
          error_check(confiq_proxy)
        end
      }

      threads << Thread.new {
        unless @result_queue.empty?
          result_proxy = ZMQ::Device.new(@result_queue[:front_end], @result_queue[:back_end])
          error_check(result_proxy)
        end
      }


      while !@close do
        $stdout << "."
        sleep 1
      end

    end

    private
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