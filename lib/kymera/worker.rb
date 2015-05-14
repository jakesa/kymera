# require_relative 'szmq/szmq'
# require 'json'
#
# module Kymera
#   class Worker
#
#     def initialize
#       # get the kymera config
#       config = Kymera::Config.new
#       # set the address where the broker is located
#       @broker_address = config.worker["broker_address"]
#       # set the address where the results bus is located
#       @result_bus_address = config.worker["result_bus_address"]
#       # set the number of concurrent tests that this user is capable of running. This is hard set to 2 times the processor count to try to take advantage of multi-threading
#       # may make this a passed in parameter or possibly something that can be changed on the fly
#       @max_threads = Kymera.processor_count
#       # get a new instance of the custom ZeroMQ context
#       @zmq = SZMQ.new
#       #For the moment I am using a push/pull configuration for running of tests.  Initial runs indicated that this may not work as all tests are being sent to just one
#       #worker at a time instead of load balancing them.  It may be more advantageous to use a request/reply structure for sending tests and managing the test run queue
#       #manually.
#       @broker_socket = @zmq.socket(@broker_address, 'reply')
#       # connect to the broker
#       @broker_socket.connect
#       # set the array for the test threads
#       @threads = []
#       # set the runner id used to identify this runner on the network
#       @runner_id = Kymera.host_name
#       # should a thread tank, I want the worker to exit. This if for debugging purposes as I am having a hanging issue on long test runs at the moment
#       Thread.abort_on_exception = true
#     end
#
#     # The method for accepting incoming test run requests. This currently blocks the console when the worker is started. This means that no user input can be accepted
#     #   I am thinking of changing that so that it will run in the background so that I can send commands to the worker for debugging or setup reasons
#     def listen
#       puts "Worker started..."
#       # start listening on the broker socket
#       @broker_socket.receive do |message|
#         #This is a preliminary kill command. I will need to give more thought into the life cycle of the workers
#         if message == 'STOP'
#           stop
#           break
#         else
#           puts "Received tests to run"
#           # pass the received message into the run_test method and then add its return value to the results
#           results = run_test(message)
#           # send the results of the test run back to the broker
#           @broker_socket.send_message results
#         end
#       end
#
#     end
#
#     #I need to pass in the runner and runner options. Thinking about using JSON to get those options and instantiate a runner object based on that information
#     #The idea is to be able to take in any number of different test runners (cucumber/rspec) without having the restart the worker object
#     #This is why passing in the runner on worker instantiation isnt really an option
#     def run_test(test_run_options)
#       puts "Setting up tests..."
#       # the test run options are send over the wire in json. This is parsing that json and turning it into a hash
#       test_run_options = JSON.parse(test_run_options)
#       # this checks to see if there are multiple tests passed in and assings those tests to the tests variable
#       tests = !test_run_options["test"].is_a?(Array) ? [test_run_options["test"]] : test_run_options["test"]
#       # because I want this tool to be cross platform, we have to account for the directory structure differences between windows and linux based machines.
#       # This checks to see what system the worker is running on and changes out the necessary characters in the tests that are passed in.
#       # This presents a little bit of an issue if the Client object is on a Mac. Will need to come back and address this later
#       if Kymera.is_linux?
#         puts "This is a linux/unix based machine. Making adjustments...."
#         # go through all the test strings and swap out the C: from the test paths with ~
#         begin
#           tests.each do |_test|
#             if _test.include? 'c:'
#               _test.gsub!('c:', '~')
#             else
#               _test.gsub!('C:', '~')
#             end
#           end
#         rescue => e
#           puts e
#         end
#       elsif Kymera.is_windows?
#         puts "This is a windows machine. Making adjustments if needed..."
#         tests.each do |_test|
#           if _test.include? '~'
#             _test.gsub!('~', 'c:')
#           end
#         end
#
#       end
#
#       puts "Received #{tests.length} test(s). Running those tests with a max number of threads of #{@max_threads}"
#
#       # spawn all of the threads needed to run the maximum number of concurrent tests
#       # this will iterate over the tests array, taking on off the top on each iteration up to the max number of threads
#       # it then passes that into the new thread along with the test_run_options and adds that thread to the threads array
#       1.upto @max_threads do |i|
#         _test = tests.pop
#         # options = {runner: test["runner"]}
#         break if _test.nil?
#         # may be should move this into its own method
#         puts "Starting thread #{i}..."
#
#         begin
#           @threads << Thread.new(_test, test_run_options) { |s_test, test_run|
#             runner = get_runner(test_run["runner"], test_run["options"], test_run["run_id"])
#             runner.run_test(s_test, test_run['branch'])
#           }
#           puts "Thread #{i} started..."
#         rescue => e
#           puts "There was a problem starting thread #{i}:\n#{e}"
#         end
#       end
#
#       # if there are tests left over, work them
#       if tests.length > 0
#         puts "There were more tests than could be run at one time. Starting test queue..."
#         while tests.length > 0
#           puts "Test Remaining: #{tests.length}"
#           puts "checking to see if there are any available threads..."
#           if num_of_alive(@threads) < @max_threads
#             puts "There was a thread available. Grabbing test..."
#             _test = tests.pop
#             if _test.nil?
#               puts "The value of the test was nil. This means there are no more tests to be executed. Will stop working tests now...."
#             else
#               puts "Here is the test to be executed: #{_test}"
#             end
#               break if _test.nil?
#             puts "Starting thread and adding it to the list of tracked threads..."
#             @threads << Thread.new(_test, test_run_options) { |s_test, test_run|
#               puts "Getting the runner for test execution..."
#               runner = get_runner(test_run["runner"], test_run["options"], test_run["run_id"])
#               puts "Running test..."
#               runner.run_test(s_test, test_run['branch'])
#             }
#           end
#           sleep 1 #I dont like this but it is for debugging purposes
#         end
#       end
#
#       # wait for all the threads to get done. I am using a check of whether or not all the threads are dead instead of the Thread#join because I am trying to
#       # negate the possibility of a thread handing all of the other threads (though this doesnt really tackle that problem. This is just another way of doing it)
#       puts "All tests have been executed. Waiting for them to complete..."
#       until threads_dead?(@threads)
#         text = "Thread count: #{@threads.count} | number of alive: #{num_of_alive(@threads)} | number of dead: #{num_of_dead(@threads)}"
#         $stdout << "\r" + (" " * text.length)
#         $stdout << "\r#{text}"
#       end
#
#       puts "\nAll test threads have completed...\nGenerating results..."
#       results = get_results(@threads)
#       puts "Clearing thread array..."
#       @threads = []
#       results
#     end
#
#     def stop
#       @test_socket.close
#     end
#
#
#     private
#
#     def get_results(threads)
#       results = ''
#       threads.each do |t|
#         results << t.value
#       end
#       results
#     end
#
#     def threads_dead?(threads)
#       result = true
#       threads.each do |t|
#         if t.alive?
#           result = false
#           break
#         end
#       end
#       result
#     end
#
#     def num_of_dead(threads)
#       count = 0
#       threads.each do |t|
#         count +=1 if !t.alive?
#       end
#       count
#     end
#
#     def num_of_alive(threads)
#       count = 0
#       threads.each do |t|
#         count +=1 if t.alive?
#       end
#       count
#     end
#
#     def thread_count
#       @threads.delete_if {|th| !th.alive?}.length
#     end
#
#     #TODO - I would like to add a way to dynamically add runners so that a user can custom build a runner and use it with this gem.
#     #Right now I am just doing some simple if/then logic to get predefined runners.
#     def get_runner(runner, options, run_id)
#       if runner.downcase == 'cucumber'
#         Kymera::Cucumber::Runner.new(options, run_id, @result_bus_address)
#       else
#         nil
#       end
#     end
#
#
#   end
# end
#
