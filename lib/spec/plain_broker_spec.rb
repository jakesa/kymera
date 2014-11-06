require 'ffi-rzmq'

context = ZMQ::Context.new
front_end_socket = context.socket(ZMQ::ROUTER)
front_end_socket.bind('tcp://*:5550')

back_end_socket = context.socket(ZMQ::DEALER)
back_end_socket.bind('tcp://*:5551')

ZMQ::Device.new(front_end_socket, back_end_socket)

#require 'rubygems'
#require 'ffi-rzmq'
#
#context = ZMQ::Context.new
#frontend = context.socket(ZMQ::ROUTER)
#backend = context.socket(ZMQ::DEALER)
#
#frontend.bind('tcp://*:5550')
#backend.connect('tcp://127.0.0.1:5551')
#
#message = []
#
#frontend.recv_strings message
#puts message
#
#backend.send_strings(message)

#poller = ZMQ::Poller.new
#poller.register(frontend, ZMQ::POLLIN)
#poller.register(backend, ZMQ::POLLIN)
#
#loop do
#  poller.poll(:blocking)
#  poller.readables.each do |socket|
#    if socket === frontend
#      socket.recv_strings(messages = [])
#      backend.send_strings(messages)
#    elsif socket === backend
#      socket.recv_strings(messages = [])
#      frontend.send_strings(messages)
#    end
#  end
#end