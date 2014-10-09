require 'ffi-rzmq'
require_relative '../../lib/kymera/v_3/kymera'
worker = Kymera::Worker.new('tcp://localhost:5557')
worker.listen