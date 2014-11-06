require 'ffi-rzmq'

context = ZMQ::Context.new
socket = context.socket(ZMQ::REP)
socket.connect 'tcp://127.0.0.1:5551'

message = ''

socket.recv_string message

puts message

socket.send_string "Got the messsage"