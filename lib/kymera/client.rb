# require_relative 'szmq/szmq'
# require 'json'
#
# module Kymera
#
#   class Client
#
#     #The client is responsible for sending the run to the distributed network. It is responsible for parsing the tests and sending all needed information to the
#     #test broker
#     #The initializer take in a broker_address(String) identifying the location of the broker on the network, a results_bus_address(String) identifying the latching point of the bus where the client and get
#     #real-time test output as the tests are being executed and real_time(Boolean) indicating whether or not this client wants to get real-time updates. This is defaulted to true
#     def initialize(real_time = true)
#       config = Kymera::Config.new
#       @broker_address = config.client["broker_address"]
#       @results_bus_address = config.client["results_bus_address"]
#       @real_time = real_time.to_s
#       @zmq = Kymera::SZMQ.new
#       @client_id = Kymera::host_name
#       Client.run_id +=1
#       @full_run_id = @client_id + (Client.run_id.to_s)
#     end
#
#     def self.run_id=(num)
#       @run_id = num
#     end
#
#     def self.run_id
#       @run_id ||= 0
#     end
#
#
#     #This is the kick off point for the test run. The tests parameter is the directory location of the tests you wish to run. This will be passed into a test parser that will determine
#     #which of the tests in the directory need to be run based on the options passed in.  The runner parameter tells the system which test runner the system should use. Right now, the only
#     #supported test runner is Cucumber, but I would like to expand this at the very least to also support Rspec.  The options parameter are the options to be passed into the specified runner
#     def run_tests(tests, runner, options, grouped = false, branch = 'develop')
#       @start_time = Time.now
#       tests = parse_tests(tests, runner, options)
#       test_run = {:tests => tests, :runner => runner, :run_id => @full_run_id, :options => options, :branch => branch, :start_time => @start_time.to_s, :grouped => grouped }
#       socket = @zmq.socket(@broker_address, 'push')
#       socket.connect
#       message = JSON.generate(test_run)
#       # puts "Sending the following message: \n"
#       # puts message
#       socket.send_message(message)
#
#       channels = ["end_#{@full_run_id}"]
#       results_feed = @zmq.socket(@results_bus_address, 'sub')
#       if @real_time == "true"
#         channels << @full_run_id
#       end
#       results_feed.subscribe(channels) do |channel, results|
#         if channel == "end_#{@full_run_id}"
#           puts "###########Test Run Results########################"
#           puts results
#           results_feed.close
#           report_time_taken
#           exit
#         else
#           puts results
#         end
#       end
#
#     end
#
#     private
#
#     #This method is what parses the test directory into runnable tests. It takes in 3 parameters, the first being tests(String). This is the location for which the system looks for
#     #executable tests. This can also be a single test. The system will still parse it to make sure that it should be run based on the passed in options.  The runner(String) tells the
#     #parser which test parser to use. Currently there is only support for a cucumber parser.  I hope to expand support for Rspec as well. The options(Array), are the options that the
#     #test parser should use for parsing out the tests.
#     def parse_tests(tests, runner, options)
#
#       #This needs to be here for the parsing of the tests. I should probably push this task off to the broker. Will keep it here for now.
#       test_path = nil
#       if Kymera.is_linux?
#         if tests.include? 'c:'
#           test_path = tests.gsub('c:','~')
#         else
#           test_path = tests.gsub('C:','~')
#         end
#       else
#         test_path = tests
#       end
#
#
#       if runner.downcase == 'cucumber'
#         parser = Kymera::Cucumber::TestParser.new(test_path, options)
#         parser.parse_tests
#       end
#     end
#
#     def report_time_taken
#       run_time = ((Time.now - @start_time)/60).to_s.match(/(\d+.\d{2})/)[0]
#       puts "Took #{run_time}m"
#     end
#
#   end
#
#
#
# end