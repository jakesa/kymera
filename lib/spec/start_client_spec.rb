require_relative '../kymera/v_2/client'
require_relative '../../lib/kymera/v_2/socket_controller'
require 'json'
message = {:this => "is", :a => 'hash', :to => 'turn', :into => 'json'}
_message = JSON.generate(message)

tests = []
2000.times do |i|
  tests << _message
end

client = Kymera::Client.new(tests, "tcp://*:5556", 'tcp://127.0.0.1:5557')
client.run_tests