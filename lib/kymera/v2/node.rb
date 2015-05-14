require_relative '../v2/node'
require 'json'

module Kymera
  class Node

    attr_accessor :workers, :registered
    attr_reader :host_name, :num_of_workers, :port, :config, :log, :status

    def initialize(config, worker_mult=nil, port=55210)
      @config = config
      @log = ''
      @host_name = Kymera.host_name
      @num_of_workers = worker_mult.nil? ? Kymera.processor_count : Kymera.processor_count * worker_mult
      @registered = false
      @port = port
      @status = 'stopped'
      # need to pass in the mongo db config here
      @registry = Kymera::Registry.new('localhost', 27017, 'kymera', 'nodes')
      @context = Kymera::SZMQ.new
      # @socket = @context.socket("inproc://worker", "request")
      # @socket.bind
      @workers = {}
      1.upto(@num_of_workers) do | n |
          worker_id = "#{@host_name}_#{n}"
          worker = Kymera::Worker.new(worker_id, @context)
          worker.listen
          socket = @context.socket("inproc://#{worker_id}", 'request')
          socket.bind
          @workers[worker_id.to_sym] = { :worker=>worker, :socket=>socket }
      end
      @listening_thread = nil
    end


    # may add the ability to start less than the number of max workers


    def register_node
      @registered = @registry.register_node(system)
    end


    def unregister_node
      @registered = !@registry.unregister_node(@host_name)
    end

    def worker_status
      alive = 0
      dead = 0
      @workers.each_value do |agent|
        alive += 1 if agent[:worker].status == 'ready'
        dead += 1 if agent[:worker].status == 'stopped'
      end
      {:alive => alive, :dead => dead }
    end


    def start_test_run(test_run)
      results = ''
      log = {}
      tasks = []
      tests = test_run["test_run"]["test"].copy
      @workers.each do |worker_id, worker|
        test = tests.pop
        break if test.nil?
        log_id = Time.now.to_s
        log[log_id] = {:status => "in progress", :worker => worker[:worker].id, :results =>''}
        tasks << Thread.new(worker, log, test, log_id, test_run) { |wkr, _log, _test, _log_id, _test_run|
          puts "sending test to the worker"
          begin
            _log[_log_id][:results] = wkr[:socket].send_message JSON.generate({:test_run => {:test => test, :runner => _test_run["test_run"]["runner"], :options => _test_run["test_run"]["options"], :run_id => _test_run["test_run"]["run_id"]}})
            _log[_log_id][:status] = "complete"
          rescue => e
            _log[_log_id][:status] = "failed: #{e}"
            puts e
            puts e.backtrace
          end

        }
      end
      tasks.each do |task|
        task.join
      end
      log.each_value do |log_data|
        results << log_data[:results]
      end
      results
    end


    def number_of_workers
      @workers.length
    end

    def configure(options)
      # configure the worker machine for the test run.
      # essentially update the repository to the specified branch for the tests to run against.
      # this needs to return a value to that the listener will send back to the caller.
      # This will likely be a string saying "ready" or "failed" depending on the out come if the branch update
      begin
        switch_to_branch(options["config"]["branch"])
      rescue => e
        puts e
        return "failed"
      end
    end


    def restart_workers
      stop_workers
      start_workers
    end

    # @note the node must be stopped before the program exits. The socket is bound to the internal port and will not let it go unless
    #   the socket is explicitly close
    def shutdown_node
      stop_workers
      unregister_node
    end


    def system
      # give back information related to the system that the worker is running on
      # OS
      # Processor count
      # worker_id/hostname
      # RAM?
      # Ruby version?
     {:node_id => @host_name, :ip_address => Kymera.ip_address, :port => @port, :processor_count => @num_of_workers, :node_os => Kymera.os, :ruby_version => Kymera.ruby_version}
    end

    def listen
      # connect to bus and listen for requests
      # put this in a thread so it is non blocking
      if @listening_thread != nil && @listening_thread.status != 'dead'
        puts "The node is already listening"
        return
      end

      @listening_thread = Thread.new(@context) { |szmq_context|
        @sub_socket = szmq_context.socket("tcp://127.0.0.1:7001", "sub")
        # sleep 3
        @pub_socket = szmq_context.socket("tcp://127.0.0.1:7000", "pub")
        # @sub_socket.connect
        @pub_socket.connect
        # @status = "ready"
        puts "Waiting for messages on #{@host_name} channel..."
        @sub_socket.subscribe(@host_name) { |channel, message|
          # puts "got message.....parsing it..."
          begin
            puts "This is the message as it came in:"
            puts message
            message = JSON.parse message
            puts "This is the message after it was parsed: "
            puts message
            if message.has_key?("test")
              puts "got message"
              puts message["test"]["run_id"]
              @pub_socket.publish_message message["test"]["run_id"], 'test received'
            elsif message.has_key?("config")
              configure(message)
              @pub_socket.publish_message(message["config"]["run_id"], JSON.generate({:config=>{:message=>"ready"}}))
            elsif message.has_key?("test_run")
              @status = "busy"
              puts "This is the message when it gets inside the test_run condition:"
              puts message
              results = JSON.generate({:results => {:run_id => message["test_run"]["run_id"], :text => start_test_run(message)}})
              @pub_socket.publish_message(message["test_run"]["run_id"], results)
              @status = "ready"
            elsif message.has_key?("stop")
              @status = 'stopped'
              Thread.kill(Thread.current)
            else
              puts "Got the following message:"
              puts "message: #{message}"
              @pub_socket.publish_message(message[message.keys[0]]["run_id"], "test received")
            end

          rescue => e
            puts "There was an error parsing the message: #{e}"
            puts e.backtrace
          end

        }
        # @socket.close
      }
      # this will wait for the thread to go to sleep before returning. This is to solve a racing condition where the status
      # was not set correctly
      while @listening_thread.status != 'sleep'
        sleep 0.1
      end
      @status = "ready"
    end

    def send_heartbeat

    end


    private
    def start_workers
      @workers.each do |agent, attr|
        # puts "This is the worker status: #{worker.status}"
        # worker.listen if worker.status == 'stopped'
        if attr[:worker].status == 'stopped'
          attr[:worker].listen
        else
          puts "Worker already started"
        end
      end
    end

    def stop_workers
      @workers.each do |agent, attr|

        if attr[:worker].status == 'ready'
          attr[:socket].send_message(JSON.generate(:stop=>''))
          attr[:socket].close
        else
          puts "worker already stopped"
        end
      end

      # @workers.each do |agent, attr|
      #   puts attr[:worker].status
      # end
      # @sockets.each do |worker_id, socket|
      #   puts "Shutting down process id: #{worker_id}...."
      #   socket.send_message(JSON.generate(:stop=>''))
      #   socket.close
      # end
      # @workers.each do |worker|
      #   puts worker.status
      # end
    end

    def switch_to_branch(branch)
      io = Object::IO.popen('hg branch')
      current_branch = io.gets.chomp
      if current_branch == branch
        update_current_branch
      else
        output = ''
        io = Object::IO.popen("hg update #{branch}")
        until io.eof?
          output << io.gets
        end
        Process.wait2(io.pid)
        puts output
        update_current_branch
      end
      "done"
    end

    def update_current_branch
      output = ''
      puts "updating branch..."
      io = Object::IO.popen("hg pull -b . -u")
      until io.eof?
        output << io.gets
      end
      Process.wait2(io.pid)
      puts "Done..."
    end

  end
end

# class Test
#
#   attr_accessor :test, :worker, :status
#
#   def initialize(test, worker)
#     @test = test
#     @worker = worker
#   end
#
#
#   def self.assign_test(test, worker)
#     Test.new(test, worker)
#   end
#
#   def to_hash
#     {:test => @test, :worker => @worker, :status => status}
#   end
#
#   def to_json
#     JSON.generate(self.to_hash)
#   end
#
#
# end





