require_relative '../kymera/v_2/worker'
require_relative '../../lib/kymera/v_2/socket_controller'

include Kymera::SocketController
context = create_context
worker = Kymera::Worker.new('tcp://127.0.0.1:5556', 'tcp://*:5557', context)
worker.start_listening
close_context(context)

#close_context(context)