require 'ffi-rzmq'

context = ZMQ::Context.new
socket = context.socket(ZMQ::REQ)
socket.connect('tcp://127.0.0.1:5550')

socket.send_string "This is a message"

reply = ''

socket.recv_string reply

puts reply