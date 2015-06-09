# require_relative 'szmq/szmq'
require 'json'

module Kymera

  class Client

    #The client is responsible for sending the run to the distributed network. It is responsible for parsing the tests and sending all needed information to the
    #test broker
    #The initializer take in a broker_address(String) identifying the location of the broker on the network, a results_bus_address(String) identifying the latching point of the bus where the client and get
    #real-time test output as the tests are being executed and real_time(Boolean) indicating whether or not this client wants to get real-time updates. This is defaulted to true
    def initialize
      @config = Kymera::Config.new
      @broker_channel = @config.broker["channel"]
      @pub_address = "tcp://#{@config.bus["address"]}:#{@config.bus["pub_port"]}"
      @sub_address = "tcp://#{@config.bus["address"]}:#{@config.bus["sub_port"]}"
      @zmq = Kymera::SZMQ.new
      @client_id = Kymera::host_name + '_c'
    end


    #This is the kick off point for the test run. The tests parameter is the directory location of the tests you wish to run. This will be passed into a test parser that will determine
    #which of the tests in the directory need to be run based on the options passed in.  The runner parameter tells the system which test runner the system should use. Right now, the only
    #supported test runner is Cucumber, but I would like to expand this at the very least to also support Rspec.  The options parameter are the options to be passed into the specified runner
    def run_tests(tests, runner, options, branch = 'develop')
      @start_time = Time.now
      tests = parse_tests(tests, runner, options)
      test_run = {:test_run => {:test => tests, :sender_id => @client_id, :runner => runner, :options => options, :branch => branch, :start_time => @start_time.to_s}}
      socket = @zmq.socket(@pub_address, 'pub')
      socket.connect
      sleep 1
      progress = Kymera::Progress.new(tests.length)
      progress.log "There are #{tests.length} to be run. Sending test run request"
      message = JSON.generate(test_run)
      socket.publish_message(@broker_channel, message)
      results_feed = @zmq.socket(@sub_address, 'sub')
      result = nil

      t = Thread.new {
          results_feed.subscribe(@client_id) do |channel, results|
            results = JSON.parse(results)
            if results.has_key?("error")
              progress.log "There was an error with the test run request: "
              progress.log results["error"]
              results_feed.close
              # report_time_taken(progress)
              result = false
              Thread.kill Thread.current
            else
              progress.log "################### Test Results #########################"
              progress.log "Test run complete. Here are the results: "
              progress.log results["results"]["text"]
              results_feed.close
              # report_time_taken(progress)
              result = true
              Thread.kill Thread.current
            end
      end
      }
      while t.alive?
        progress.refresh
      end
      $stdout.print "\n"
      result
    end


    private

    #This method is what parses the test directory into runnable tests. It takes in 3 parameters, the first being tests(String). This is the location for which the system looks for
    #executable tests. This can also be a single test. The system will still parse it to make sure that it should be run based on the passed in options.  The runner(String) tells the
    #parser which test parser to use. Currently there is only support for a cucumber parser.  I hope to expand support for Rspec as well. The options(Array), are the options that the
    #test parser should use for parsing out the tests.
    def parse_tests(tests, runner, options)

      #This needs to be here for the parsing of the tests. I should probably push this task off to the broker. Will keep it here for now.
      test_path = nil
      if Kymera.is_linux?
        if tests.include? 'c:'
          test_path = tests.gsub('c:','~')
        else
          test_path = tests.gsub('C:','~')
        end
      else
        test_path = tests
      end


      if runner.downcase == 'cucumber'
        parser = Kymera::Cucumber::TestParser.new(test_path, options)
        parser.parse_tests
      end
    end

    def report_time_taken(progress)
      run_time = ((Time.now - @start_time)/60).to_s.match(/(\d+.\d{2})/)[0]
      progress.log "Took #{run_time}m"
    end

  end



end