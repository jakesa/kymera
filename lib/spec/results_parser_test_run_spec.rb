require_relative '../../lib/kymera/v_4/kymera'
#zmq = Kymera::SZMQ.new
#
#socket = zmq.socket('tcp://*:5556', 'pull')
#socket.bind
#socket.receive do |results|
#  puts results
#end

#context = ZMQ::Context.new
#socket = context.socket(ZMQ::PULL)
#socket.bind('tcp://127.0.0.1:5555')
#message = ''
#socket.recv_string(message)
#puts message

results_parser = Kymera::TestResultsCollector.new('tcp://*:5556', 'tcp://127.0.0.1:7000')
results_parser.listen
