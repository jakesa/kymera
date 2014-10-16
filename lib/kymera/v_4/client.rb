require_relative 'szmq/szmq'
require 'json'

module Kymera

  class Client

    def initialize(broker_address, results_address, results_bus_address, real_time = true)
      @broker_address = broker_address
      @results_address = results_address
      @results_bus_address = results_bus_address
      @real_time = real_time
      @zmq = Kymera::SZMQ.new

    end

    def run_tests(tests, runner, options)
      tests = parse_tests(tests, runner, options)
      test_run = {:tests => tests, :runner => runner, :options => options}
      socket = @zmq.socket(@broker_address, 'push')
      socket.connect
      message = JSON.generate(test_run)
      socket.send_message(message)
      #if @real_time
      #  start_live_feed
      #end

      #wait_for_results
      socket.close

    end

    private

    #TODO - This is a prototype and needs to be tested
    def start_live_feed
      Thread.new {
        results_feed = @zmq.socket(@results_bus_address, 'sub')
        results_feed.subscribe('test_run_id')
        results_feed.receive do |message|
          puts message
        end
      }
    end

    def wait_for_results
      trap ("INT") do
        puts "\nReceived interrupt..."
        socket.close
      end
      socket = @zmq.socket(@results_address, 'pull')
      socket.connect
      socket.receive do |results|
        puts results
      end
    end

    def parse_tests(tests, runner, options)
      if runner.downcase == 'cucumber'
        parser = Kymera::Cucumber::TestParser.new(tests, options)
        parser.parse_tests
      end
    end


  end



end