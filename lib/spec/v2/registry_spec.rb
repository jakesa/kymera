require_relative '../../../lib/kymera'

describe Kymera::Registry do

  before :each do
    Kymera::MongoDriver.debug = false
  end

  it 'should initialize with defaults' do
    registry = Kymera::Registry.new
    expect(registry.address).to eq "localhost"
    expect(registry.port).to eq 27017
    expect(registry.database).to eq "default_db"
    expect(registry.collection).to eq "default_collection"
  end

  context "nodes" do


    it 'should register the node' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      result = registry.register_node({:node_id => Kymera.host_name, :ip_address => Kymera.ip_address, :port => 27017, :processor_count => Kymera.processor_count, :node_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      expect(result).to eq(true)
    end

    it 'should get a list of registered nodes' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      registry.register_node({:node_id => Kymera.host_name, :ip_address => Kymera.ip_address, :port => 27017, :processor_count => Kymera.processor_count, :node_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      docs = registry.get_registered_nodes
      expect(docs.empty?).to eq false
    end

    it 'should unregister the node' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      node_id = "#{Kymera.host_name}#{rand 100}"
      registry.register_node({:node_id => node_id, :ip_address => Kymera.ip_address, :port => 27017, :processor_count => Kymera.processor_count, :node_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      expect(registry.unregister_node(node_id)).to_not eq nil
    end

    it 'should not unregister a node if the node does not exist' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      expect(registry.unregister_node("adfhsadjkfh")).to eq nil
    end

    it 'should update the registered node list when a node is unregistered' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      node_id = "#{Kymera.host_name}#{rand 100}"
      registry.register_node({:node_id => node_id, :ip_address => Kymera.ip_address, :port => 27017, :processor_count => Kymera.processor_count, :node_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      expect(registry.unregister_node(node_id)).to_not eq nil
      result = false
      registry.get_registered_nodes.each do |node|
        result = node["node_id"] == node_id
        break if result
      end
      expect(result).to eq false
    end

  end

  context "workers" do

    it 'should register the worker' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      result = registry.register_worker({:worker_id => Kymera.host_name, :ip_address => Kymera.ip_address, :port => 55214, :worker_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      expect(result).to eq(true)
    end

    it 'should get a list of registered workers' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      registry.register_worker({:worker_id => Kymera.host_name, :ip_address => Kymera.ip_address, :port => 27017, :worker_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      docs = registry.get_registered_workers
      expect(docs.empty?).to eq false
    end

    it 'should unregister the worker' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      worker_id = "#{Kymera.host_name}#{rand 100}"
      registry.register_worker({:worker_id => worker_id, :ip_address => Kymera.ip_address, :port => 27017, :worker_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      expect(registry.unregister_worker(worker_id)).to_not eq nil
    end

    it 'should not unregister a worker if the node does not exist' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      expect(registry.unregister_worker("adfhsadjkfh")).to eq nil
    end

    it 'should update the registered worker list when a worker is unregistered' do
      registry = Kymera::Registry.new("localhost", 27017, "kymera")
      worker_id = "#{Kymera.host_name}#{rand 100}"
      registry.register_worker({:worker_id => worker_id, :ip_address => Kymera.ip_address, :port => 27017, :worker_os => Kymera.os, :ruby_version => Kymera.ruby_version})
      expect(registry.unregister_worker(worker_id)).to_not eq nil
      result = false
      registry.get_registered_workers.each do |worker|
        result = worker["worker_id"] == worker_id
        break if result
      end
      expect(result).to eq false
    end

  end


end