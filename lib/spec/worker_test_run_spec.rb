require_relative '../../lib/kymera/v_4/kymera'


runner = Kymera::Cucumber::Runner.new("-p default")

worker = Kymera::Worker.new('tcp://127.0.0.1:5555', '127.0.0.1:5556')
worker.listen