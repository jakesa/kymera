require_relative 'szmq/szmq'
require 'json'

module Kymera

  class TestResultsParser

    def initialize(inc_address, out_address )
      @zmq = Kymera::SZMQ.new
      @inc_socket = @zmq.socket(inc_address, 'pull')
      @out_socket = @zmq.socket(out_address, 'push')
      @inc_socket.bind
      @out_socket.connect
    end

    def listen
      test_count = ''
      run_id = ''
      results = ''
      runner = ''
      count = 0
      @inc_socket.receive do |message|
        parsed_message = JSON.parse message
        if count < 1
          run_id = parsed_message["run_id"]
          test_count = parsed_message["test_count"].to_i
          runner = parsed_message["runner"]
          results << parsed_message["results"]
          test_count -= 1
        elsif test_count > 0
          results << parsed_message["results"]
          test_count -= 1
        else
          finalize_results(results, runner)
          test_count = ''
          run_id = ''
          results = ''
          runner = ''
          count = 0
        end

        count +=1

      end

    end

    private

    def finalize_results(results, runner)
      if runner.downcase == 'cucumber'
        r_results = Kymera::Cucumber::ResultsParser.summarize_results(results)
        @out_socket.send_message(r_results)
      end
    end





  end


end