require "dcell"
require_relative 'actors'
require_relative 'actor'
require_relative 'platform_utils'

module Kymera

  module Node

    def self.start_server(redis_address, redis_port)

      begin
        DCell.start :id => 'node_server', :addr => "tcp://#{Kymera.ip_address}:5521",
                    :registry => {
                        :adapter => 'redis',
                        :host    => redis_address,
                        :port    => redis_port.to_i
                    }
      rescue
        raise "There was a problem starting the server.  The Redis instance was likely not started"
      end
    end

    def self.register_node

      DCell.start :id => "node_#{Kymera.host_name}", :addr => "tcp://#{Kymera.ip_address}:5521",
                  :directory => {
                       :id   => 'node_server',
                       :addr => 'tcp://127.0.0.1:2042'
                   }

    end

    def self.register_actors
      ActorGroup.run!
    end

    def self.node_server_address
      nodes = DCell::Node.all
      address = nil
      nodes.each do |node|

        while address.nil? || i < 5
          address = node.addr if node.id == 'node_server'

        end

      end


    end


  end

end