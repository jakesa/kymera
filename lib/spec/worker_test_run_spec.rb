# require_relative '../../lib/kymera'
require 'kymera'

# args = ARGV
# if args[0] == 'remote'
#   worker = Kymera::Worker.new('tcp://10.6.49.60:5552', 'tcp://10.6.49.60:5556', 'tcp://10.6.49.60:7000')
# else
#   worker = Kymera::Worker.new('tcp://127.0.0.1:5552', 'tcp://127.0.0.1:5556', 'tcp://127.0.0.1:7000')
# end
# worker.listen
Kymera.start_worker
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
