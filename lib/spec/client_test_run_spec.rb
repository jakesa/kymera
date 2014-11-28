# require_relative '../../lib/kymera'
require 'kymera'
#zmq = Kymera::SZMQ.new
#socket = zmq.socket('tcp://127.0.0.1:5550', 'push')
#socket.connect
#tests = ['c:/apollo/source/integration_tests/features/login_and_session/login.feature', 'c:/apollo/source/integration_tests/features/login_and_session/logout.feature','c:/apollo/source/integration_tests/features/login_and_session/login_rememberMe.feature:10',
#         'c:/apollo/source/integration_tests/features/login_and_session/login_rememberMe.feature:16','c:/apollo/source/integration_tests/features/login_and_session/login_rememberMe.feature:24', 'C:\apollo\source\integration_tests\features\posting\research_tools\trip_miles.feature:17',
#'C:\apollo\source\integration_tests\features\posting\research_tools\trip_miles.feature:22', 'C:\apollo\source\integration_tests\features\posting\research_tools\trip_miles.feature:27']
#hash = {:tests => tests, :runner => 'cucumber', :options => ['-p default']}
#message = JSON.generate(hash)
#socket.send_message(message)
#socket.close
#threads = []
#%w(these are the messages that I am using to test the load balancing of the broker if this works then I have the method that I am going to use for running tests in the distributed framework).each do |message|
#socket = zmq.socket('tcp://127.0.0.1:5555', 'request')
#  socket.connect
#  reply = socket.send_message(message)
#  puts "#{message} -> #{reply}"
#  socket.close
#end

#threads.each do |thread|
#  thread.join
#end

#context = ZMQ::Context.new
#socket = context.socket(ZMQ::PUSH)
#socket.connect('tcp://127.0.0.1:5556')
#socket.send_string("This is a message")

client = Kymera::Client.new('tcp://127.0.0.1:5550','tcp://127.0.0.1:7001')
# client = Kymera::Client.new('tcp://10.6.49.60:5550','tcp://10.6.49.60:7001')
# client.run_tests('c:/apollo/source/integration_tests/features/login_and_session/login.feature', 'cucumber', ['-p default'])
client.run_tests('~/apollo/source/integration_tests/features/login_and_session/login.feature', 'cucumber', ['-p default'])
#client.run_tests('C:\apollo\source\integration_tests\features', 'cucumber', ['-p dev_parallel'])
#client.run_tests('c:/apollo/source/integration_tests/features', 'cucumber', ['-p dev'])