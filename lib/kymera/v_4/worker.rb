require_relative 'szmq/szmq'
require 'json'

class Worker

  def initialize(test_address, results_address)
    @test_address = test_address
    @results_address = results_address
    @zmq = SZMQ.new
    @test_socket = @zmq.socket(@test_address, 'pull')
    @results_socket = @zmq.socket(@results_address, 'push')
    @test_socket.connect
    @results_socket.connect
  end

  def listen
    @test_socket.receive do |message|
      if message == 'STOP'
        stop
        break
      else
        run_test(message)
      end
    end

  end

  #I need to pass in the runner and runner options. Thinking about using JSON to get those options and instantiate a runner object based on that information
  #The idea is to be able to take in any number of different test runners (cucumber/rspec) without having the restart the worker object
  #This is why passing in the runner on worker instantiation isnt really an option
  def run_test(test)
    test = JSON.parse(test)
    @runner.run_test(test)
  end

  def stop
    @test_socket.close
    @results_socket.close
  end


end