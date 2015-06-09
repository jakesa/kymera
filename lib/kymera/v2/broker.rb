# require_relative 'szmq/szmq'
require 'json'

module Kymera

  class Broker

    attr_accessor :config, :context, :registry, :results, :log, :listening_thread, :host_name, :channel, :status, :bundle_id, :run_ids
    def initialize(config, context, registry)
      @config = config
      @context = context
      @registry = registry
      @results = ''
      @log = {}
      @listening_thread = nil
      @monitor_thread = nil
      @host_name = Kymera.host_name
      @channel = config.broker["channel"]
      @status = 'stopped'
      @bundle_id = 0
      @run_ids = []
      @host_name = Kymera.host_name
    end


    def listen
      # connect to bus and listen for requests
      # put this in a thread so it is non blocking
      monitor_test_runs
      if @listening_thread != nil && @listening_thread.status != 'dead'
        puts "The broker is already listening"
        return
      end
      # p 10
      @listening_thread = Thread.new(@context) { |szmq_context|
        # p 11
        @sub_socket = szmq_context.socket("tcp://#{@config.bus["address"]}:#{@config.bus["sub_port"]}", "sub")
        # p 12
        @pub_socket = szmq_context.socket("tcp://#{@config.bus["address"]}:#{@config.bus["pub_port"]}", "pub")
        # p 13
        @pub_socket.connect
        sleep 1
        # p 14
        @log = {}
        puts "Waiting for messages on #{@channel} channel..."
        # p 15
        @sub_socket.subscribe(@channel) { |channel, message|
          begin
            # p 16
            message = JSON.parse message
            # p "Got a message: #{message}"
            # p "These are the keys########################################"
            # p message.keys
            # p 17
            if message.has_key?("test")
              # puts "got message"
              # puts message["test"]["run_id"]
              p "##############################################################"
              p "Received a test message from #{message["test"]["sender_id"]}"
              p message
              p "##############################################################"
              @pub_socket.publish_message message["test"]["sender_id"], 'test received'
            # p 18
            elsif message.has_key?("test_run")
              # p 19
              run_id = message["test_run"]["sender_id"] + Time.now.to_i.to_s
              @log[run_id] = {}
              @log[run_id]["results"] = ''
              @log[run_id]["test_count"] = message["test_run"]["test"].length
              p "The number of tests expected to run: #{@log[run_id]['test_count']}"
              @log[run_id]["runner"] = message["test_run"]["runner"]
              @log[run_id]["start_time"] = message["test_run"]["start_time"]
              @run_ids << run_id
              monitor_test_runs
              # test_count = message["test_run"]["test"].length
              # check to see if this broker is currently in the middle of a test run (@status == 'busy')
              # if it is busy, send a message back to the user telling them there is currently a test run in progress
              # possibly add functionality for queuing test runs later
              # need to add a check to see if there are any nodes actually registered in the system. If there are not, I need to inform the client
              if @status == 'busy' || @status == 'stopped'
                #TODO: I need to add functionality for test_run queuing
                @pub_socket.publish_message(message["test_run"]["sender_id"], JSON.generate(:error => "There is currently a test run in progress"))
              else
                # p 21
                @status = "busy"
                bundle_and_run_tests(message, run_id, @pub_socket)
                # p 22
                while !message["test_run"]["test"].empty? do
                  # p 23
                  # binding.pry
                  bundle_and_run_tests(message, run_id, @pub_socket)
                  sleep 5
                end
                  # sleep 20
              end
              # if there are no runs currently in progress get a list of registered nodes
              # check to see if the registered nodes are available (send a message to them asking for their info (name, number of workers, and so on))
              # if they are none available, report back that no nodes are currently available for test run (this may not be necessary but we'll see)
              # wait for a predetermined amount of time for responses from the nodes and collect the responses
              # for the nodes that replied, bundle a group of tests based on the maximum number of workers for that node
              # record those tests in a log and which node they are going to and send them (might useful to include a batch number)
              # after getting a reply with the results for a batch, record the results of that batch and repeat the above step until the test array is empty
              # after all tests are accounted for, send the collected results to the results parser for parsing
              # send the parsed results back to the client
              # send the original results to be parsed by the html parser
              # send those html parsed results to the database for use by the Leo web application

              #this is going to fail results and batches are at the same level. need to add a check for this

            elsif message.has_key?("stop")
              # p 28
              @status = 'stopped'
              puts "Got the shutdown signal"
              Thread.kill(Thread.current)

            elsif message.has_key?("results")
              # p 29
              #   p "############Got results, Processing them part 1#################"
              #   p "These are the log keys"
              #   p @log.keys
              #   p "These are the message keys"
              #   p @log[message["results"]["run_id"]][message["results"]["bundle_id"].to_i]
              #   p message
              if @log.has_key?(message["results"]["run_id"])
                # p "############Got results, Processing them part 2#################"
                @log[message["results"]["run_id"]][message["results"]["bundle_id"].to_i][:results] = message["results"]["text"]
                @log[message["results"]["run_id"]][message["results"]["bundle_id"].to_i][:end_time] = Time.now
              end
            end

              # p 32
          rescue => e
            # p 33
            puts "There was an error parsing the message on the broker: #{e}"
            puts e.backtrace
          end
        }
        # @socket.close
      }
      # this will wait for the thread to go to sleep before returning. This is to solve a racing condition where the status
      # was not set correctly
      # p 34
      while @listening_thread.status != 'sleep' || @listening_thread.status.nil?
        # p @listening_thread.status
        # p @listening_thread.value
        sleep 0.1
      end
      @status = "ready"
    end

    def shutdown
      p "sending shutdown signal"
      @status = "stopped"
      Thread.kill(@listening_thread)
    end



    private

    def monitor_test_runs
      # p "#######################Starting the monitoring of test runs##########################"
      @monitor_thread ||= Thread.new {
        # p "Starting the loop"
        loop do
          # p "Inside the loop"
          # begin
          if @log.empty?
            p "Log is empty"
          else
            # p "This is the log####################"
            # p @log
            # p "###################################"
            p "The log is not empty"
            begin
            @log.each do |run_id, bundle|
              #if run_id[:status] != "done"
              if @log[run_id][:status] != "complete"

                status = []
                bundle.each do |k,v|
                  # puts "####################Bundles####################"
                  # puts k
                  # puts v
                  # puts k.class
                  # puts "################################################"
                  if k.class == Fixnum
                    if v[:end_time].nil?
                      status << false
                    else
                      status << true
                    end
                  end
                end

                if !status.include?(false) && !status.empty?

                  # puts "#####################the log reported this item done ########################"
                  # puts @log
                  # puts @log.keys
                  # p 24
                  @log[run_id].each do |key, b|
                    # p 25
                    # p "#########The Run was done processing data ##############"
                    # p key
                    # p b
                    # p "#######################"
                    if key.class == Fixnum
                      @log[run_id]["results"] << b[:results]
                    end
                  end unless @log[run_id].nil?
                  # p "#################################These are the results ##################################"
                  # p @log[run_id]["results"]
                  Kymera::TestResultsCollector.new.finalize_results(@log[run_id]["test_count"],
                                                                    run_id,
                                                                    @log[run_id]["results"],
                                                                    @log[run_id]["runner"],
                                                                    @log[run_id]["start_time"])
                  @log[run_id][:status] = "complete"
                  @status = "ready"
                end

              end
            end
            rescue => e
              puts e
              puts e.backtrace
            end
          end
          sleep 2
        end
      }

    end

    def bundle_and_run_tests(test_run, run_id, socket, nodes=nil)
      # p 103
      # p test_run
      # p run_id
      # p socket
      # p nodes
      #TODO: I need to figure out what I want to do when there are no nodes available (either all are busy or there are none registered)
      nodes ||= @registry.get_registered_nodes
      p nodes
      nodes.each do |node|
        # p 104
        unless node["status"] == "busy"
          bundle = []
          # p '################################'
          # p "These are the number of workers"
          # p node
          # p node["num_of_workers"]
          # p '################################'
          0.upto node["num_of_workers"].to_i do
            test = test_run["test_run"]["test"].pop
            break if test.nil?
            bundle << test
          end
          # p 105
          start_time = Time.now
          socket.publish_message(node["node_id"], JSON.generate(:test_run => {:test => bundle, :run_id => run_id, :bundle_id => @bundle_id, :sender_id => @channel,
                                                                           :options => test_run["test_run"]["options"], :runner => test_run["test_run"]["runner"]}))
          # p 106
          @log[run_id][@bundle_id] = {:node_id => node["node_id"], :start_time => start_time, :end_time => nil, :test_count => bundle.length, :test_bundle => bundle, :results => '', :status => "in progress"}
          @bundle_id +=1
          # p 107
        end
      end
    end
  end

end