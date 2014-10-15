require_relative '../../lib/kymera/v_4/kymera'

zmq = Kymera::SZMQ.new
socket = zmq.socket('tcp://*:5555', 'push')
socket.bind
hash = {:test => 'c:/apollo/source/integration_tests/features/login_and_session/login.feature', :runner => 'cucumber', :options => ['-p default']}
message = JSON.generate(hash)
socket.send_message(message)
socket.close




#context = ZMQ::Context.new
#socket = context.socket(ZMQ::PUSH)
#socket.connect('tcp://127.0.0.1:5556')
#socket.send_string("This is a message")