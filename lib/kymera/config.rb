require 'redis'
require 'redis-namespace'
module Kymera


  module Config

    def self.set_redis_server(redis_address, redis_port)
      ENV['REDIS_ADDRESS'] = redis_address
      ENV['REDIS_PORT'] = redis_port
      "The server addres is #{ENV['REDIS_ADDRESS']} and the port is #{ENV['REDIS_PORT']}."
    end

    def self.get_redis_address
      if ENV['REDIS_ADDRESS'].nil? || ENV['REDIS_PORT'].nil?
        raise "The redis server has not been defined. Please call Kymera::Config.set_redis_server to set the address and port."
      end
      [ENV['REDIS_ADDRESS'], ENV['REDIS_PORT']]
    end

    #def self.set_up_redis
    #  redis_address, redis_port = self.get_redis_address
    #  redis = Redis.new(:host => redis_address, :port => redis_port)
    #  Redis::Namespace.new 'dcell_production', :redis => redis
    #end

  end



end