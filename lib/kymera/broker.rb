# require_relative 'szmq/szmq'
# require 'json'
#
# module Kymera
#
#   class Broker
#
#     def initialize
#       config = Kymera::Config.new
#       @zmq = Kymera::SZMQ.new
#       Thread.abort_on_exception = true
#       #This will change once I get the worker registry up and running. When that is up, there will be one connection spawned for
#       #each of the workers that are connected. Edit - Thats actually not sustainable. The number of workers should be able to change
#       #dynamically without impact to the broker. An inventory check should be made at the start of every new test run. There should also
#       # be some logic to handle the disconnection of workers in the middle of a test run.
#       @num_of_connections = config.broker["number_of_connections"]
#       #This socket is for getting tests from the client
#       @client_address = "tcp://*:#{config.broker["client_listening_port"]}"
#       @internal_address = "tcp://*:#{config.broker["internal_worker_port"]}"
#       @worker_address = "tcp://*:#{config.broker["worker_listening_port"]}"
#       @test_socket = @zmq.socket(@client_address, 'pull')
#       @test_socket.bind
#       @front_end = @zmq.socket(@internal_address, 'router')
#       @back_end = @zmq.socket(@worker_address, 'dealer')
#       @proxy = Thread.new {@zmq.start_proxy(@front_end, @back_end)}
#       @results = ''
#     end
#
#     #This brings up the broker so that it can receive test run requests.
#     def start_broker
#       puts "Broker started..."
#       @test_socket.receive do |tests|
#         puts "Received test run request.."
#         start_test_run(tests)
#       end
#     end
#
#     private
#
#     #This is the start of the test run and is called when the broker receives a test run request
#     def start_test_run(test_run)
#       puts 'Starting test run...'
#       test_run = JSON.parse(test_run)
#       puts 'Copying over tests..'
#       tests = test_run["tests"].copy
#       threads = []
#       puts "Checking for group configuration...#{test_run['grouped']}"
#       # puts "This is the test run message:\n"
#       # puts "#{test_run}"
#       if test_run["grouped"] || test_run["grouped"].to_s.downcase == 'true'
#         puts 'Grouping tests....'
#         tests = group_tests(tests)
#       end unless test_run["grouped"].nil?
#
#       @test_count = test_run["tests"].length
#       report_test_config(test_run)
#
#       if tests.length > @num_of_connections.to_i
#         puts "Test count was higher than connections. Starting tests and initiating run queue"
#         1.upto @num_of_connections.to_i do
#           test = tests.pop
#           break if test.nil?
#           threads << run_test(test, test_run)
#         end
#         work_queue(threads, tests, test_run)
#
#       else
#         puts "Test count was not higher than the connections. Starting all tests."
#         1.upto tests.length do
#           test = tests.pop
#           break if test.nil?
#           threads << run_test(test, test_run)
#         end
#
#       end
#
#       until threads_dead?(threads) do
#         # text = "Thread count: #{threads.count} | number of alive: #{num_of_alive(threads)} | number of dead: #{num_of_dead(threads)}"
#         # $stdout << "\r" + (" " * text.length)
#         # $stdout << "\r#{text}"
#         # puts "Threads still working...#{num_of_alive(threads)}"
#       end
#
#       puts "Test run completed....\nGathering results from threads..."
#       results = get_results(threads)
#       Kymera::TestResultsCollector.new.finalize_results(test_run["test_count"], test_run["run_id"], results, test_run["runner"], test_run["start_time"])
#
#     end
#
#     def get_results(threads)
#       results = ''
#       threads.each do |t|
#         results << t.value
#       end
#       results
#     end
#
#     def group_tests(tests)
#       #This creates a group for each of the available connection as specified by the @num_of_connections variable
#       #It will then iterate over all of the tests and add a test to each of the groups
#       #at the end of the iteration, if any groups are left empty, they are deleted and the trimmed array is returned
#       groups = []
#
#       puts "Setting group containers..."
#       1.upto @num_of_connections.to_i do
#         groups << []
#       end
#
#       puts "Distributing tests..."
#       while tests.length > 0
#         groups.each do |group|
#           test = tests.pop
#           group << test unless test.nil?
#           break if test.nil?
#         end
#       end
#       groups.delete_if {|group| group.empty?}
#     end
#
#
#     #If there are tests left over after the initial test start up, they are placed into a queue.  The queue is then worked until all tests in the queue have been executed
#     def work_queue(threads, tests, options)
#       until tests.empty?
#         threads.delete_if {|t| !t.alive?}
#         if threads.length < @num_of_connections
#           test = tests.pop
#           break if test.nil?
#           threads << run_test(test, options)
#         end
#       end
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
#     #This runs each test individually
#     def run_test(test, options)
#       port = @internal_address.split(':')[2]
#       Thread.new {
#         zmq = Kymera::SZMQ.new
#         message = JSON.generate({:test => test, :runner => options["runner"], :options => options["options"], :run_id => options["run_id"],
#                                  :test_count => @test_count, :branch => options["branch"], :start_time => options["start_time"]})
#         socket = zmq.socket("tcp://127.0.0.1:#{port}", 'request')
#         socket.connect
#         puts "Sending: #{message}"
#         results = socket.send_message(message)
#         socket.close
#         results
#       }
#     end
#
#     #This gives a print out of the test run that was received
#     def report_test_config(test_run)
#       puts "Running test with the following configuration:"
#       puts "Branch: #{test_run["branch"]}"
#       puts "Runner: #{test_run["runner"]}"
#       puts "Run ID: #{test_run["run_id"]}"
#       puts "Runner Options: #{test_run["options"]}"
#       puts "Total number tests: #{test_run["tests"].length}"
#     end
#
#
#   end
#
# end