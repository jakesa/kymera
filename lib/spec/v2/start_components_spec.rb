require_relative '../../../lib/kymera'

context = Kymera::SZMQ.new
registry = Kymera::Registry.new('localhost', 27017, 'kymera', 'nodes')
config = Kymera::Config.new
node = Kymera::Node.new(config)
sleep 1
node.register_node
sleep 1
node.listen
broker = Kymera::Broker.new(config, context, registry)
broker.listen

loop do

end