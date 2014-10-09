require 'ffi-rzmq'
require_relative '../../lib/kymera/v_3/kymera'

broker = Kymera::Broker.new
broker.set_test_queue('tcp://127.0.0.1:5556', 'tcp://*:5557')
broker.start_broker