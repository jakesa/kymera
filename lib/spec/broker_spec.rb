require 'ffi-rzmq'
require_relative '../../lib/kymera/v_3/kymera'

broker = Kymera::Broker.new
broker.set_test_queue('tcp://*:5556', 'tcp://*:5557')
broker.set_confiq_queue('tcp://*:5540', 'tcp://*:5541')
broker.set_result_queue('tcp://*:5530', 'tcp://*:5531')
broker.start_broker
