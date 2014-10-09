require_relative '../kymera/v_2/worker'
require_relative '../kymera/v_2/client'
require_relative '../../lib/kymera/v_2/socket_controller'

include Kymera::SocketController
context = create_context
worker = Kymera::Worker.new('tcp://127.0.0.1:5556', 'tcp://*:5557', context)
client = Kymera::Client.new(['these', 'are', 'the', 'tests'], 'tcp://*:5556', 'tcp://127.0.0.1:5557', context)
worker.start_listening
client.run_tests
close_context(context)
