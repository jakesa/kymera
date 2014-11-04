require 'ffi-rzmq'
require_relative '../../lib/kymera'
#require_relative '../../lib/kymera/v_3/kymera'
#
#broker = Kymera::Broker.new
#broker.set_test_queue('tcp://*:5556', 'tcp://*:5557')
#broker.set_confiq_queue('tcp://*:5540', 'tcp://*:5541')
#broker.set_result_queue('tcp://*:5530', 'tcp://*:5531')
#broker.start_broker

#zmq = Kymera::SZMQ.new
#
#front_end = zmq.socket('tcp://*:5555', 'router')
#back_end = zmq.socket('tcp://*:5556', 'dealer')
#zmq.start_proxy(front_end, back_end)

#context = ZMQ::Context.new
#front_end = context.socket(ZMQ::ROUTER)
#back_end = context.socket(ZMQ::DEALER)

broker = Kymera::Broker.new('tcp://*:5550', 'tcp://127.0.0.1:5551', 'tcp://*:5552', 20)
broker.start_broker



