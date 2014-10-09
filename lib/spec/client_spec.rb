require 'ffi-rzmq'
require_relative '../../lib/kymera/v_3/kymera'
client = Kymera::Client.new('tcp://localhost:5556')
client.send_message("This is the message")