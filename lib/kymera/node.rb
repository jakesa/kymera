require "dcell"
require_relative 'actors'
require_relative 'actor'
require_relative 'platform_utils'
require 'redis'

module Kymera

  class Node

    attr_accessor :redis, :redis_address, :redis_port

    def initialize(redis_address = nil, redis_port = nil)
      @redis_address = redis_address
      @redis_port = redis_port

      if @redis_address != nil && @redis_port != nil
        @redis = Redis.new(:host => @redis_address, :port => @redis_port)
      else
        puts "WARNING: There was no redis information passed in. "

      end


    end


    def start_server(redis_address = @redis_address, redis_port = @redis_port)

      if redis_address.nil? || redis_port.nil?
        raise "A redis address and port number are required because Node was instantiate with a redis address or port."

      else
        @redis_address = redis_address
        @redis_port = redis_port
        @redis = Redis.new(:host => @redis_address, :port => @redis_port)
      end

      server_address = "tcp://#{Kymera.ip_address}:5521"
      begin
        DCell.start :id => 'node_server', :addr => server_address,
                    :registry => {
                        :adapter => 'redis',
                        :host    => @redis_address,
                        :port    => @redis_port.to_i
                    }

        @redis.set(:node_server, server_address)
      rescue
        raise "There was a problem starting the server.  The Redis instance was likely not started"
      end
    end

    def register_node(redis_address = @redis_address, redis_port = @redis_port)
      if redis_address.nil? || redis_port.nil?
        raise "A redis address and port number are required because Node was instantiate with a redis address or port."
      else
        @redis_address = redis_address
        @redis_port = redis_port
        @redis = Redis.new(:host => @redis_address, :port => @redis_port)
      end

      DCell.start :id => "node_#{Kymera.host_name}", :addr => "tcp://#{Kymera.ip_address}:5521",
                  :directory => {
                       :id   => 'node_server',
                       :addr => @redis.get(:node_server)
                   }

    end

    def register_actors
      ActorGroup.run!
    end

  end

end