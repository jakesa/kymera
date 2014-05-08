require "dcell"
require_relative 'actors'
require_relative 'actor'
require_relative 'platform_utils'
require 'redis'

module Kymera

  module Node

    #attr_accessor :redis, :redis_address, :redis_port

    # This is the constructor to the Node class. It can take in the address and port to the redis server but it is not requred.  However, if you dont specify it here, than it needs to be supplied
    # to all other instance methods.
    #def initialize(redis_address = nil, redis_port = nil)
    #  @redis_address = redis_address
    #  @redis_port = redis_port
    #
    #  if @redis_address != nil && @redis_port != nil
    #    @redis = Redis.new(:host => @redis_address, :port => @redis_port)
    #  else
    #    puts "WARNING: There was no redis information passed in. "
    #  end
    #
    #end


    # This kicks off the node server.  This server is where all other nodes will connect and register to. It would be ideal to have this live on the same machine as the redis instance but is not required
    # Because this can live on the same machine as redis, you can pass in the local host address of 127.0.0.1.  The method will dynamically get the machines public ip address for registering with redis.
    def self.start_server(redis_address = nil, redis_port = nil)

      # Checks to see if the redis info was passed in. If it was not, it raises an error saying as much. Otherwise it will setup the redis client.
      if redis_address.nil? || redis_port.nil?
        redis_address, redis_port = Kymera::Config.get_redis_address
        #raise "A redis address and port number are required because Node was instantiate with a redis address or port."
      #else
      #  p 2
      #  @redis_address = redis_address
      #  @redis_port = redis_port
      end

      server_address = "tcp://#{Kymera.ip_address}:5521"

      # This starts the node server using dcell.  If there was a problem it raises an error. However, when connecting to the redis server, if it is not there will just hang rather than raise an error
      # TODO - Add some timeout logic
      begin

        DCell.start :id => 'node_server', :addr => server_address,
                    :registry => {
                        :adapter => 'redis',
                        :host    => redis_address,
                        :port    => redis_port.to_i
                    }

        #TODO - Dont think this line is needed. Will check later
        #@redis.set(:node_server, server_address)
      rescue
        raise "There was a problem starting the server.  The Redis instance was likely not started"
      end
    end


    #TODO - Clean up the retun value of this function. It's currntly a bunch of junk that wouldnt be useful to the user
    # This method registers the machine as a node capable of running tests with actors.  While this can be done on the same machine as the node_server, it is not recommended.
    def self.register_node(redis_address = nil, redis_port = nil)
      if redis_address.nil? || redis_port.nil?
        redis_address, redis_port = Kymera::Config.get_redis_address
      #else
      #  @redis_address = redis_address
      #  @redis_port = redis_port
      #
      end
      redis = set_up_redis(redis_address, redis_port)
      DCell.start :id => "node_#{Kymera.host_name}", :addr => "tcp://#{Kymera.ip_address}:5521",
                  :directory => {
                       :id   => 'node_server',
                       :addr => redis.get(:node_server)
                   },
                  :registry => {
                      :adapter => 'redis',
                      :host    => redis_address,
                      :port    => redis_port.to_i
                  }


    end

    #def self.register_actors
    #  ActorGroup.run!
    #end

    def self.register_actors
      processor_count = Kymera::processor_count * 2
      count = 1
      begin
        1.upto(processor_count){ Actor.supervise_as("actor_#{Kymera::host_name}_#{count}".to_sym, "actor_#{Kymera::host_name}_#{count}", 2); count += 1}
        puts "The following actors were created: #{get_local_actors}"
      rescue => e
        puts e
        puts "There was a problem with creating one or more of the actors"
      end
    end


    #unregister_node will remove this node from the node server making it unavailable for test execution
    def self.unregister_node
      node = DCell.me
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


    #TODO: This is not working correctly. Will have to come back and take a look later
    #def self.unregister_actors
    #  DCell.me.actors.each {|actor| DCell.me[actor].terminate}
    #end



    # This method returns all of the nodes that have a registered actor pool
    def self.get_nodes
      _nodes = []
      begin
        p "###############Getting Nodes###################################"
        nodes = DCell.registry.nodes
        nodes.each do |node|
          p "######{node}########"
          p "actor_#{node.gsub('node_', '')}_1".to_sym
          p DCell::Node[node].all.include? ("actor_#{node.gsub('node_', '')}_1".to_sym)
           if DCell::Node[node].all.include? ("actor_#{node.gsub('node_', '')}_1".to_sym)
             p "Inside the loop: #{node}"
             DCell::Node[node].all.each do |n|
               _nodes << DCell::Node[node][n] if n.to_s.include?("actor_#{node.gsub('node_', '')}")
             end
           end
        end
      rescue => e
        puts e
        raise 'It appears that the config has not been set up or that the computer has not been registered to the node network.'
      end
      _nodes
    end


    def get_all_actors
      actors = []
      begin
        nodes = self.get_nodes
        nodes.each do |node|
          node.actors.each {|actor| actors << actor}
        end
      end
      actors
    end

    def self.get_local_actors
      DCell.me.actors
    end

    private

    # This adds the namespace to the redis instance that dcell uses.  Without this wrapper, the calls to the redis database would fail.
    def self.set_up_redis(redis_address, redis_port)
      redis = Redis.new(:host => redis_address, :port => redis_port)
      Redis::Namespace.new 'dcell_production', :redis => redis
    end

  end

end