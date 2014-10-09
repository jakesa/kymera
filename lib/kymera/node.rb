
require_relative 'actors'
require_relative 'actor'
require_relative 'platform_utils'
require 'redis'

module Kymera

  module Node



    # This kicks off the node server.  This server is where all other nodes will connect and register to. It would be ideal to have this live on the same machine as the redis instance but is not required
    # Because this can live on the same machine as redis, you can pass in the local host address of 127.0.0.1.  The method will dynamically get the machines public ip address for registering with redis.
    def self.start_server(redis_address = nil, redis_port = nil)

    end


    # This method registers the machine as a node capable of running tests with actors.  While this can be done on the same machine as the node_server, it is not recommended.
    def self.register_node(redis_address = nil, redis_port = nil)

    end


    def self.register_actors

    end


    #unregister_node will remove this node from the node server making it unavailable for test execution
    def self.unregister_node
      redis_address, redis_port = Kymera::Config.get_redis_address
      redis = set_up_redis(redis_address, redis_port)
      result = redis.hdel('nodes', node.id)

      if result == 1
        puts 'Node Successfully Unregistered'
        raise SystemExit
      else
        'Failed'
      end
    end


    # This method returns all of the nodes that have a registered actor pool
    def self.get_nodes
    end


    def self.get_all_actors
    end

    def self.get_local_actors
    end

    private

    # This adds the namespace to the redis instance that dcell uses.  Without this wrapper, the calls to the redis database would fail.
    def self.set_up_redis(redis_address, redis_port)
      redis = Redis.new(:host => redis_address, :port => redis_port)
      Redis::Namespace.new 'dcell_production', :redis => redis
    end

  end

end