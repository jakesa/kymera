require 'ffi-rzmq'
require_relative '../../lib/kymera/v_4/kymera'
#client = Kymera::Client.new('tcp://localhost:5556')
#client.send_message("This is the message")
zmq = SZMQ.new

client = zmq.socket('tcp://127.0.0.1:5555', 'request')
client.connect

reply = client.send_message("This is a test")
puts reply

#context = ZMQ::Context.new
#socket = context.socket(ZMQ::PUSH)
#socket.bind('tcp://*:5555')
#socket.send_string("This is a message")
#reply = ''
#unless socket.recv_string(reply) == -1
#  socket.recv_string(reply)
#  puts reply
#end