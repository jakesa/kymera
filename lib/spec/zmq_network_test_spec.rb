require 'ffi-rzmq'

context = ZMQ::Context.new
socket = context.socket(ZMQ::REQ)
socket.connect 'tcp://10.6.49.101:5000'

message = "This is a message"
socket.send_string message

reply = ''
socket.recv_string(reply)

puts reply