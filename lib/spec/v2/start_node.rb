require_relative '../../../lib/kymera'

trap ("INT") do
  puts "\nStopping node..."
  # node.shutdown
  exit 0
end

config = Kymera::Config.new
node = Kymera::Node.new(config)
sleep 1
node.register_node
sleep 1
node.listen

loop do

end