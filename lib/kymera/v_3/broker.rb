require 'ffi-rzmq'

module Kymera

  attr_accessor :context, :front_end_socket, :back_end_socket

  class Broker

    def initialize
      @context = Kymera::MessageSystem.context
      @test_queue = {}
      @config_queue = {}
      @result_queue = {}
    end

    #set up the test segment push/push sockets
    def set_test_queue(client_addr, worker_addr)
      #get the front end socket
      puts "Setting up test front end"
      @test_queue[:front_end] = @context.socket(ZMQ::ROUTER)
      #bind the front end socket
      $stdout << "."
      #This is what the client/requester sees
      @test_queue[:front_end].setsockopt(ZMQ::LINGER, 0)
      error_check(@test_queue[:front_end].bind(client_addr))
      #get the back end socket
      puts "Setting up test back end"
      @test_queue[:back_end] = @context.socket(ZMQ::DEALER)
      @test_queue[:back_end].setsockopt(ZMQ::LINGER, 0)
      $stdout << "."
      #This is what the worker sees
      error_check(@test_queue[:back_end].bind(worker_addr))
      $stdout << "."
    end

    #setup the config segment push/pull socket
    def set_confiq_queue(client_addr, worker_addr)
      @config_queue[:front_end] = @context.socket(ZMQ::ROUTER)
      error_check(@config_queue[:front_end].bind(client_addr))
      @config_queue[:back_end] = @context.socket(ZMQ::DEALER)
      error_check(@config_queue[:back_end].bind(worker_addr))
    end

    #setup the results segment push/pull socket
    def set_result_queue(client_addr, worker_addr)
      @result_queue[:front_end] = @context.socket(ZMQ::ROUTER)
      error_check(@result_queue[:front_end].bind(client_addr))
      @result_queue[:back_end] = @context.socket(ZMQ::DEALER)
      error_check(@result_queue[:back_end].bind(worker_addr))
    end

    #start all of the configured listeners
    def start_broker
      #This array is not currently used other than to store the threads. May come in use later
      threads = []
      @close = false
      puts "Starting broker.."

      #trap and clean close logic. This will go through and close all of the sockets after detecting an interrupt
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

      #the ZMQ proxies are blocking, so I had to put them each in their own thread
      threads << Thread.new {
        unless @test_queue.empty?
          puts "Starting test queue.."
          test_proxy = ZMQ::Device.new(@test_queue[:front_end], @test_queue[:back_end])
          #error_check(test_proxy)
        end
      }

      threads << Thread.new {
        unless @config_queue.empty?
          confiq_proxy = ZMQ::Device.new(@config_queue[:front_end], @config_queue[:back_end])
          #error_check(confiq_proxy)
        end
      }

      threads << Thread.new {
        unless @result_queue.empty?
          result_proxy = ZMQ::Device.new(@result_queue[:front_end], @result_queue[:back_end])
          #error_check(result_proxy)
        end
      }


      #loop until a close is detected. This allows for all listeners to stay running
      #Note: the output of this is just for debugging (to see that its actually looping). Will take out at a later time
      while !@close do
        text = "\r"
        text << "working"
        space = " "
        0.upto(2) do
          STDOUT.print text
          sleep 0.5
          STDOUT.print "\r#{space * (text.length - 1)}"
          sleep 0.5
        end
      end

    end

    private

    #checking that any ZMQ request is handled properly
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