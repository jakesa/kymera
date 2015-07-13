require_relative '../../../lib/kymera'


trap ("INT") do
  puts "\nStopping broker..."
  # node.shutdown
  exit 0
end

context = Kymera::SZMQ.new
registry = Kymera::Registry.new('localhost', 27017, 'kymera', 'nodes')
config = Kymera::Config.new
broker = Kymera::Broker.new(config, context, registry)
broker.listen

loop do

end