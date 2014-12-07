require_relative 'szmq/szmq'
require 'json'
require 'mongo'

module Kymera

  class MongoDriver
    include Mongo


    def self.log_results(log, address = "localhost", port = 27017, database = 'default_db', collection = 'default_collection')
      puts "Sending results to mongodb..."
      MongoDriver.new(address, port, database, collection).write_log(log)
    end


    #This can be initialized by specifying the address and the port of the mongodb server. By default, this expects that the
    #mongodb server is located on the same machine as the calling code. A collection name will also be defaulted if not passed in.
    #By default, this will be 'default_db'
    def initialize(address = "localhost", port = 27017, database = 'default_db', collection = 'default_db')
      puts "Initializing db connection.."
      @db_client = MongoClient.new(address, port).db(database)
      puts "Assigning collection..."
      @collection = collection
    end


    #The @param log needs to be a JSON string.
    def write_log(log)
      puts "Getting collection..."
      coll = @db_client["#{@collection}"]
      puts "Sending insert request.."
      coll.insert(JSON.parse log)
      puts "Request completed"
    end

  end

end