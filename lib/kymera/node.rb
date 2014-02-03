require "dcell"
require_relative 'actors'
require_relative 'actor'
require_relative 'platform_utils'

module Kymera

  class Node

    def start_server(redis_address, redis_port)

      server_address = "tcp://#{Kymera.ip_address}:5521"
      begin
        DCell.start :id => 'node_server', :addr => server_address ,
                    :registry => {
                        :adapter => 'redis',
                        :host    => redis_address,
                        :port    => redis_port.to_i
                    }
          DCell::Global[:node_server] = server_address
      rescue
        raise "There was a problem starting the server.  The Redis instance was likely not started"
      end
    end

    def register_node

      DCell.start :id => "node_#{Kymera.host_name}", :addr => "tcp://#{Kymera.ip_address}:5521",
                  :directory => {
                       :id   => 'node_server',
                       :addr => DCell::Global[:node_server]
                   }

    end

    def register_actors
      ActorGroup.run!
    end
    #
    #def self.node_server_address
    #  nodes = DCell::Node.all
    #  address = nil
    #  nodes.each do |node|
    #
    #    while address.nil? || i < 5
    #      address = node.addr if node.id == 'node_server'
    #
    #    end
    #
    #  end
    #
    #
    #end


  end

end