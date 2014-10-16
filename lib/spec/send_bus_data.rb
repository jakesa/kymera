require_relative '../../lib/kymera/v_4/kymera'

#zmq = Kymera::SZMQ.new
#
#pub_socket = zmq.socket('tcp://127.0.0.1:7000', 'pub')
#pub_socket.connect
#pub_socket.publish_message('results', 'these are results')

context = ZMQ::Context.new
socket = context.socket(ZMQ::PUB)
socket.connect('tcp://127.0.0.1:7000')
sleep 5
socket.send_string('results', ZMQ::SNDMORE)
socket.send_string('these are some more results')


