require_relative 'szmq/szmq'
require 'json'

module Kymera
  class Worker

    def initialize(test_address, results_address, result_bus_address)
      @test_address = test_address
      @results_address = results_address
      @result_bus_address = result_bus_address
      @zmq = SZMQ.new
      #For the moment I am using a push/pull configuration for running of tests.  Initial runs indicated that this may not work as all tests are being sent to just one
      #worker at a time instead of load balancing them.  It may be more advantageous to use a request/reply structure for sending tests and managing the test run queue
      #manually.
      @test_socket = @zmq.socket(@test_address, 'reply')
      @results_socket = @zmq.socket(@results_address, 'push')
      @result_bus_socket = @zmq.socket(@result_bus_address, 'pub')
      @result_bus_socket.connect
      @test_socket.connect
      #Even though this is a push socket, I am connecting instead of binding because the static point is going to be the pull socket where the results are aggregated
      #Static points are bound, dynamic points are connected
      @results_socket.connect
    end

    def listen
      @test_socket.receive do |message|
        #This is a preliminary kill command. I will need to give more thought into the life cycle of the workers
        if message == 'STOP'
          stop
          break
        else
          results = run_test(message)
          @results_socket.send_message(results)
          @test_socket.send_message ''
        end
      end

    end

    #I need to pass in the runner and runner options. Thinking about using JSON to get those options and instantiate a runner object based on that information
    #The idea is to be able to take in any number of different test runners (cucumber/rspec) without having the restart the worker object
    #This is why passing in the runner on worker instantiation isnt really an option
    def run_test(test)
      test = JSON.parse(test)
      runner = get_runner(test["runner"], test["options"], test["run_id"])
      results = runner.run_test(test["test"])
      JSON.generate({:run_id => test["run_id"], :test_count => test["test_count"], :runner => test["runner"], :results => results})
    end

    def stop
      @test_socket.close
      @results_socket.close
    end

    private

    #TODO - I would like to add a way to dynamically add runners so that a user can custom build a runner and use it with this gem.
    #Right now I am just doing some simple if/then logic to get predefined runners.
    def get_runner(runner, options, run_id)
      if runner.downcase == 'cucumber'
        Kymera::Cucumber::Runner.new(options, run_id, @result_bus_socket)
      else
        nil
      end
    end


  end
end

