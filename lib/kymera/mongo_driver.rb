require_relative 'szmq/szmq'
require 'json'
require 'mongo'

module Kymera

  class MongoDriver
    include Mongo

    attr_accessor :address, :port, :database, :collection, :collection, :db_client

    def self.debug
      @@debug
    end

    def self.debug=(value)
      @@debug = value
    end

    # a way of writing to the database without explicitly calling the constructor
    # see#initialize
    def self.log_results(log, address = "localhost", port = 27017, database = 'default_db', collection = 'default_collection')
      puts "Sending results to mongodb..." if @@debug
      @address, @port, @database, @collection = address, port, database, collection
      MongoDriver.new(address, port, database, collection).write_log(log)
    end

    # constructor for the MongoDriver.
    # @param address [String] the location of the database. Defaults to "localhost"
    # @param port [Fixnum] the port that the database is listening on. Defaults to 27017
    # @param database [String] the name of the database that you are writing to. Defaults to "default_db"
    # @param collection [String] the name of the collection that your documents belong in. Defaults to "default_collection"
    def initialize(address = "localhost", port = 27017, database = 'default_db', collection = 'default_collection')
      @@debug ||= false
      puts "Initializing db connection.." if @@debug
      @db_client = MongoClient.new(address, port).db(database)
      puts "Assigning collection..." if @@debug
      @collection = collection
    end


    # write a document to the database
    # @param log [JSON] needs to be a JSON string.
    # @return [void]
    def write_log(log)
      puts "Getting collection..." if @@debug
      coll = @db_client["#{@collection}"]
      puts "Sending insert request.." if @@debug
      coll.insert(JSON.parse log)
      puts "Request completed" if @@debug
    end

    # check to see if a particular document exists
    # @param attribute [Hash{String => Value}]
    # @return [Boolean]
    def exists?(attribute)
      coll = @db_client["#{@collection}"]
      a = coll.find(attribute).to_a
      a.empty? ? false : true
    end

    # remove the document via the specified attribute and value
    # @param attribute_hash [Hash{Symbol => String}] the field/attribute and value of the document you want to delete
    # @return [void]
    def remove(attribute_hash)
      coll = @db_client["#{@collection}"]
      coll.remove(attribute_hash)
    end

    # remove all of the documents on the collection
    # @param collection [String] the collection that you want to remove all of the documents from
    # @return [void]
    def remove_all(collection)
      coll = @db_client[collection]
      coll.remove
    end

    # get an array of the documents in the specified collection
    # @param collection_name [String] the name of the collections that you want the list of documents from
    # @return [Array<Hash{String => String}] the list of documents
    def get_collection(collection_name = @collection)
      coll = @db_client[collection_name.to_s]
      docs = coll.find.to_a
      docs.each do |doc|
        doc.delete("_id")
      end
      docs
    end

    def update(id, attribute_hash)
      coll = @db_client["#{@collection}"]
      # binding.pry
      coll.update({"#{@collection.chop}_id".to_sym => id}, {"$set" => attribute_hash})
    end


  end

end