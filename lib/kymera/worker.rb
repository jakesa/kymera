require_relative 'szmq/szmq'
require 'json'

module Kymera
  class Worker

    def initialize
      config = Kymera::Config.new
      @test_address = config.worker["broker_address"]
      @results_address = config.worker["result_collector_address"]
      @result_bus_address = config.worker["result_bus_address"]
      @max_threads = Kymera.processor_count * 2
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
      @threads = []
      @runner_id = Kymera.host_name
    end

    def listen
      puts "Worker started..."
      @test_socket.receive do |message|
        #This is a preliminary kill command. I will need to give more thought into the life cycle of the workers
        if message == 'STOP'
          stop
          break
        else
          # results = run_test(message)
          # @results_socket.send_message(results)
          puts "Received tests to run"
          run_test(message, @results_socket)
          @test_socket.send_message ''
        end
      end

    end

    #I need to pass in the runner and runner options. Thinking about using JSON to get those options and instantiate a runner object based on that information
    #The idea is to be able to take in any number of different test runners (cucumber/rspec) without having the restart the worker object
    #This is why passing in the runner on worker instantiation isnt really an option
    def run_test(test, results_socket)
      puts "Setting up tests..."
      test = JSON.parse(test)
      runner = get_runner(test["runner"], test["options"], test["run_id"])
      tests = !test["test"].is_a?(Array) ? [test["test"]] : test["test"]
      if Kymera.is_linux?
        puts "This is a linux/unix based machine. Making adjustments...."
        begin
          tests.each do |_test|
            if _test.include? 'c:'
              _test.gsub!('c:', '~')
            else
              _test.gsub!('C:', '~')
            end
          end
        rescue => e
          puts e
        end
      end

      puts "Received #{tests.length} test(s). Running those tests with a max number of threads of #{@max_threads}"

      #TODO: Right now I am passing around a reference to a socket that is created on instantiation, I really should be creating and destroying a socket
      #for each thread I am creating not passing one in.
      0.upto @max_threads do
        _test = tests.pop
        break if _test.nil?
        @threads << Thread.new {send_results(runner.run_test(_test, test['branch']), test, results_socket)}
      end

      puts "Created #{thread_count} threads...."

      if tests.length > 0
        puts "There were more tests than could be run at one time. Starting test queue."
      end
      while tests.length > 0
        if thread_count < @max_threads
          _test = tests.pop
          @threads << Thread.new {send_results(runner.run_test(_test, test['branch']), test, results_socket)}
        end
      end

      @threads.each do |t|
        t.join
      end unless @threads.empty?

    end

    def stop
      @test_socket.close
      @results_socket.close
    end

    private

    def send_results(results, message, socket)
      begin
        socket.send_message(JSON.generate({:run_id => message["run_id"], :runner_id => @runner_id, :test_count => message["test_count"], :runner => message["runner"], :results => results, :start_time => message["start_time"]} ))
      rescue => e
        puts e
      end

    end

    def thread_count
      @threads.delete_if {|th| !th.alive?}.length
    end

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

