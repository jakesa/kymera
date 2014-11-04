require 'kymera'
threads = []

trap('INT') do
  threads.each do |thread|
    thread.kill
  end unless threads.empty?
end

#Results bus thread
threads << Thread.new {
  bus = Kymera::ResultsBus.new('tcp://*:7000', 'tcp://*:7001')
  bus.start_bus
}

#Broker thread
threads << Thread.new {
  broker = Kymera::Broker.new('tcp://*:5550', 'tcp://127.0.0.1:5551', 'tcp://127.0.0.1:5552', 20)
  broker.start_broker
}

#Results collector thread
threads << Thread.new {
  results_collector = Kymera::TestResultsCollector.new('tcp://*:5556', 'tcp://127.0.0.1:7000')
  results_collector.listen
}

#Worker thread
threads << Thread.new {
  worker = Kymera::Worker.new('tcp://127.0.0.1:5552', 'tcp://127.0.0.1:5556', 'tcp://127.0.0.1:7000')
  worker.listen
}

#give stuff a chance to start up
sleep 2

client = Kymera::Client.new('tcp://127.0.0.1:5550','tcp://127.0.0.1:7001')
client.run_tests('~/apollo/source/integration_tests/features/login_and_session/logout.feature', 'cucumber', ['-p default'])
#client.run_tests('c:/apollo/source/integration_tests/features', 'cucumber', ['-p dev'])





