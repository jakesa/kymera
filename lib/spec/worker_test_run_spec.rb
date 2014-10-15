require_relative '../../lib/kymera/v_4/kymera'

worker = Kymera::Worker.new('tcp://127.0.0.1:5555', 'tcp://127.0.0.1:5556')
worker.listen