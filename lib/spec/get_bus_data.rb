require_relative '../../lib/kymera/v_4/kymera'

#zmq = Kymera::SZMQ.new
#sub_socket = zmq.socket('tcp://127.0.0.1:7001', 'sub')
#sub_socket.subscribe('results') do |channel, message|
#  puts message
#end


context = ZMQ::Context.new
socket = context.socket(ZMQ::SUB)
socket.setsockopt(ZMQ::SUBSCRIBE, 'results')
socket.connect('tcp://127.0.0.1:7001')

channel = ''
message = ''

loop do
  socket.recv_string(channel)
  socket.recv_string(message)
  puts channel
  puts message
end
