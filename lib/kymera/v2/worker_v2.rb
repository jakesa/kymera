  require 'json'

module Kymera
  class Worker

    # class attributes
    # threads: the threads currently running
    # max_threads: the maximum number of threads that can be active at any one time
    # worker_id: the hostname of the machine that the worker is running on
    # config: an instance of the config class that contains all of the addresses
    # listening_thread: the thread that the worker is using for receiving requests. Having this in a thread will allow me to
    #   still make calls to the worker object since the #listen will no longer be blocking
    # registered: tell the user whether the worker has successfully registered with the registry or not
    attr_accessor :worker_id, :config, :listening_thread, :registered
    attr_reader :status

    def initialize(worker_id, szmq_context)
      # get the kymera config
      # get the necessary addresses
      # set registered to false
      @worker_id = worker_id
      @context = szmq_context
      @config = Kymera::Config.new
      @listening_thread = nil
      @status = "stopped"
    end

    alias_method :id, :worker_id

    def listen
      # also needs to check whether or not the worker is registered. If it is not registered, attempt to register. If successful, preform the check below
      # needs to check to see if there is a thread assigned to @listening_thread and if there is, check to see if the thread is alive of not
      # if both of the above conditions are false or if there is a thread in @listening_thread but it is not alive, then create a new thread that starts listening and assign it to @listening_thread
      # otherwise display a warning saying that the worker is already listening and do nothing
      # process incoming requests
      raise "A SZMQ::Context object must be passed in when you start listening on a worker" if @context.nil?
      # should write something that monitors this thread so that in the case that it dies or crashes, it could be restarted
      @listening_thread = Thread.new(@context) { |szmq_context|
        @socket = szmq_context.socket("inproc://#{@worker_id}", "reply")
        @socket.connect
        @status = "ready"
        @socket.receive { |message|
          begin
            message = JSON.parse message

            if message.has_key?("test")
              @socket.send_message 'test received'
            elsif message.has_key? "config"
              results = configure(message)
              puts results
              @socket.send_message results
              #todo dont know that this is really useful
            elsif message.has_key? "stop"
              @socket.send_message ''
              @socket.close
              # need to kill thread?
              @status = "stopped"
              break
            elsif message.has_key? "test_run"
              @status = "running test"
              @socket.send_message run_test(message)
              @status = "ready"
            else
              @socket.send_message 'didnt get a test but got something else'
            end

          rescue => e
            puts e
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

    end


    # def register_worker
      # attempt to connect to the registry and register
      # if successful, set @registered to true and call #start_heartbeat
      # else raise an error
    # end

    # def unregister_worker
      # attempt to connect to the registry and unregister the worker
      # if successful, call #stop_heatbeat
      # else raise an error
    # end

    def start_heartbeat
      # once successfully registered send out periodic heartbeat on the bus letting the registry know that you are still alive

    end
    #
    # def stop_heartbeat
    #   # stop sending the heartbeat
    # end


    def available?
      @status == "ready"
    end




    private

    def run_test(test_run)
      # execute the test_run passed in
      puts test_run
      runner = get_runner(test_run['test_run']["runner"], test_run['test_run']['options'], test_run['test_run']["run_id"])
      runner.run_test(test_run['test_run']['test'])
    end

    #TODO - I would like to add a way to dynamically add runners so that a user can custom build a runner and use it with this gem.
    #Right now I am just doing some simple if/then logic to get predefined runners.
    def get_runner(runner, options, run_id)
      if runner.downcase == 'cucumber'
        Kymera::Cucumber::Runner.new(options, run_id)
      else
        nil
      end
    end

  end
end
