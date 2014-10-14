require 'ffi-rzmq'
require_relative '../../lib/kymera/v_4/kymera'
#worker = Kymera::Worker.new('tcp://localhost:5557')
#worker.listen
zmq = SZMQ.new

worker = zmq.socket('tcp://127.0.0.1:5556', 'reply')
worker.connect
worker.receive {|message| puts "This is the message I got: '#{message}'"; "I got the message"}
#context = ZMQ::Context.new
#socket = context.socket(ZMQ::PULL)
#socket.connect('tcp://127.0.0.1:5555')
#received_message = ''
#socket.recv_string(received_message)
#puts received_message
