require_relative '../../lib/kymera/v_4/kymera'

bus = Kymera::ResultsBus.new('tcp://*:7000', 'tcp://*:7001')
bus.start_bus

#context = ZMQ::Context.new
#front_end_socket = context.socket(ZMQ::XSUB)
#back_end_socket = context.socket(ZMQ::XPUB)
#
#front_end_socket.connect('tcp://127.0.0.1:7000')
#back_end_socket.bind('tcp://*:7001')
#
#ZMQ::Device.new(front_end_socket, back_end_socket)