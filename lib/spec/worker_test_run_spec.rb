require_relative '../../lib/kymera'

worker = Kymera::Worker.new('tcp://127.0.0.1:5552', 'tcp://127.0.0.1:5556', 'tcp://127.0.0.1:7000')
worker.listen

#zmq = Kymera::SZMQ.new
#socket = zmq.socket('tcp://127.0.0.1:5556', 'reply')
#socket.connect
#
#
#socket.receive do |message|
#  sleep rand(20)
#  puts message
#  socket.send_message('')
#end
