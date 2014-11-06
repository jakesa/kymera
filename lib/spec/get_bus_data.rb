require_relative '../../lib/kymera'

zmq = Kymera::SZMQ.new
sub_socket = zmq.socket('tcp://127.0.0.1:7001', 'sub')

#sub_socket2 = zmq.socket('tcp://127.0.0.1:7001', 'sub')

  sub_socket.subscribe('results') do |channel, message|
    $stdout << "."
    puts channel
    puts message
  end
#Thread.new {
#  sub_socket2.subscribe('BVTCQD0CZ11') do |channel, message|
#    $stdout << "."
#  end
#}
#
#
#sub_socket.subscribe('end_BVTCQD0CZ11') do |channel, message|
#  puts channel
#  puts message
#end


#context = ZMQ::Context.new
#socket = context.socket(ZMQ::SUB)
#socket.setsockopt(ZMQ::SUBSCRIBE, 'end_BVTCQD0CZ11')
#socket.connect('tcp://127.0.0.1:7001')
#
#socket_2 = context.socket(ZMQ::SUB)
#socket_2.setsockopt(ZMQ::SUBSCRIBE, 'BVTCQD0CZ11')
#socket_2.connect('tcp://127.0.0.1:7001')
#
#channel = ''
#message = ''
#
#loop do
#  socket.recv_string(channel)
#  socket.recv_string(message)
#  puts channel
#  puts message
#end
