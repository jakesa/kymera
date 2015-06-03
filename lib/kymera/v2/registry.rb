require 'json'

module Kymera
  class Registry


    attr_accessor :registered_workers, :registered_nodes, :address, :port, :database, :collection
    attr_reader :mongo_driver

    def initialize(address = 'localhost', port = 27017, database = 'default_db', collection = 'default_collection')
      @address, @port, @database, @collection = address, port, database, collection
      @registered_workers = []
      @registered_nodes = []
      update_nodes
      update_workers
    end

    # register a node
    # @param node [Hash{String => Value}] the node that you want to register
    # @return [Boolean] will return true if the registration was successful and false if not
    # @todo need to add a check for the nodes existance before trying to register. We dont want multiple nodes of the same name in the database
    def register_node(node)
      mongo_driver = Kymera::MongoDriver.new(address, port, database, 'nodes')
      if mongo_driver.exists?("node_id" => node[:node_id])
        puts "#{node[:node_id]} is already registered"
        return true
      end
      register = {}
      register[:node_id] = node[:node_id]
      register[:status] = node[:status]
      register[:ip_address] = node[:ip_address]
      register[:port] = node[:port]
      register[:register_date] = Time.now.to_datetime
      register[:num_of_workers] = node[:processor_count]
      register[:os] = node[:node_os]
      register[:ruby_version] = node[:ruby_version]

      mongo_driver.write_log(JSON.generate(register))
      if mongo_driver.exists?("node_id" => register[:node_id])
        @registered_nodes << register
        true
      else
        false
      end
    end

    # register a worker
    # @param worker [Hash{String => Value}] the worker that you want to register
    # @return [Boolean] will return true if the registration was successful and false if not
    def register_worker(worker)
      mongo_driver = Kymera::MongoDriver.new(address, port, database, 'workers')
      register = {}
      register[:worker_id] = worker[:worker_id]
      register[:ip_address] = worker[:ip_address]
      register[:port] = worker[:port]
      register[:register_date] = Time.now.to_datetime
      register[:os] = worker[:worker_os]
      register[:ruby_version] = worker[:ruby_version]

      mongo_driver.write_log(JSON.generate(register))
      if mongo_driver.exists?("worker_id" => register[:worker_id])
        @registered_workers << register
        true
      else
        false
      end

    end

    # unregister a node
    # @param node_id [String] the node_id of the node you want to unregister
    # @return [true, nil] will return true if successful and nil if there was nothing to remove
    # @todo may need to add exception handling at some point and may have to move away from the way that I am updating the registered node array
    def unregister_node(node_id)
      mongo_driver = Kymera::MongoDriver.new(address, port, database, 'nodes')
      if mongo_driver.exists?("node_id" => node_id)
        mongo_driver.remove("node_id" => node_id)
        update_nodes
        true
      else
        nil
      end
    end

    # unregister a worker
    # @param worker_id [String] the worker_id of the worker you want to unregister
    # @return [true, nil] will return true if successful and nil if there was nothing to remove
    # @todo may need to add exception handling at some point and may have to move away from the way that I am updating the registered worker array
    def unregister_worker(worker_id)
      mongo_driver = Kymera::MongoDriver.new(address, port, database, 'workers')
      if mongo_driver.exists?("worker_id" => worker_id)
        mongo_driver.remove("worker_id" => worker_id)
        update_workers
      else
        nil
      end
    end

    # get the list of registered workers
    # @return [Array<Hash>] an array of hashes with the information of the registered workers
    def get_registered_workers
      @registered_workers
    end

    # get the list of registered nodes
    # @return [Array<Hash>] an array of hashes with the information of the registered nodes
    def get_registered_nodes
      @registered_nodes
    end

    def update_node_value(node_id, attribute_hash)
      mongo_driver = Kymera::MongoDriver.new(address, port, database, 'nodes')
      mongo_driver.update(node_id, attribute_hash)
    end


    private

    # update the registered nodes array by making a call to the database
    def update_nodes
      mongo_driver = Kymera::MongoDriver.new(address, port, database, 'nodes')
      @registered_nodes = mongo_driver.get_collection('nodes')
    end

    # update the registered workers array by makeing a call to the database
    def update_workers
      mongo_driver = Kymera::MongoDriver.new(address, port, database, 'workers')
      @registered_workers = mongo_driver.get_collection('workers')
    end




  end


end