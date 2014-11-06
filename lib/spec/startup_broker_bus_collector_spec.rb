require 'kymera'
threads = []

trap('INT') do
  threads.each do |thread|
    thread.kill
  end unless threads.empty?
  @close = true
end

#Results bus thread
threads << Thread.new {
  bus = Kymera::ResultsBus.new('tcp://*:7000', 'tcp://*:7001')
  bus.start_bus
}

#Broker thread
threads << Thread.new {
  broker = Kymera::Broker.new('tcp://*:5550', 'tcp://*:5551', 'tcp://*:5552', 20)
  broker.start_broker
}

#Results collector thread
threads << Thread.new {
  results_collector = Kymera::TestResultsCollector.new('tcp://*:5556', 'tcp://10.6.49.60:7000')
  results_collector.listen
}

loop do
  raise SystemExit if @close
end