require_relative 'szmq/szmq'
require_relative 'mongo_driver'
require 'chronic'
require 'json'

module Kymera

  class TestResultsCollector

    def initialize(inc_address, out_address )
      @zmq = Kymera::SZMQ.new
      @inc_socket = @zmq.socket(inc_address, 'pull')
      @out_socket = @zmq.socket(out_address, 'pub')
      @inc_socket.bind
      @out_socket.connect
    end

    def listen
      puts "Test collector started..."
      test_count = ''
      start_test_count = ''
      @run_id = ''
      results = ''
      runner = ''
      start_time = ''
      count = 0
      @inc_socket.receive do |message|
        parsed_message = JSON.parse message
        if count < 1
          @run_id = parsed_message["run_id"]
          test_count = parsed_message["test_count"].to_i
          start_test_count = parsed_message["test_count"]
          runner = parsed_message["runner"]
          results << parsed_message["results"]
          start_time = parsed_message["start_time"]
          puts 'Results run started with the following configuration:'
          puts "Run ID: #{@run_id}"
          puts "Test count: #{test_count}"
          test_count -= 1
          count +=1
        elsif test_count > 0
          results << parsed_message["results"]
          test_count -= 1
        end

        if test_count <= 0
          finalize_results(start_test_count, @run_id, results, runner, start_time)
          test_count = ''
          @run_id = ''
          results = ''
          runner = ''
          start_time = ''
          count = 0
        end


      end

    end

    private

    def finalize_results(test_count, run_id, results, runner, start_time)
      if runner.downcase == 'cucumber'

        begin
          #r_results = Kymera::Cucumber::ResultsParser.summarize_results(results)
          puts "Summarizing results.."
          r_results = Kymera::Cucumber::ResultsParser.summarize_results(results)
          puts "Getting pass count..."
          pass_count = Kymera::Cucumber::ResultsParser.scenario_counts[:pass]
          puts "Getting fail count..."
          fail_count = Kymera::Cucumber::ResultsParser.scenario_counts[:fail]
          # r_results = Kymera::Cucumber::ResultsParser.summarize_results(results)
          puts "Converting results to html..."
          html_results = Kymera::Cucumber::HTMLResultsParser.to_html(results)
          puts "Converting summary to html..."
          html_summary = Kymera::Cucumber::HTMLResultsParser.to_html(r_results)
          puts "Setting end time"
          end_time = Time.now
          # puts html_results
          # Kymera::MongoDriver.log_results(build_test_log(test_count, run_id, results, r_results), '10.6.49.83', 27017, 'apollo', 'test_runs')
          puts "Starting database logging processes..."
          Kymera::MongoDriver.log_results(build_test_log(test_count, run_id, html_results, html_summary, start_time, end_time.to_s, pass_count, fail_count), '10.6.49.83', 27017, 'apollo', 'test_runs')
          puts "Setting run id..."
        rescue => e
          puts "There was an error in the logging process:"
          puts e
        ensure
          run_id = "end_#{@run_id}"
          puts "Sending results to client..."
          @out_socket.publish_message(run_id, r_results)
        end
      end
    end

    def build_test_log(test_count, run_id, results, summary, start_time, end_time, pass_count, fail_count)
      begin
        log_message = {}
        log_message["run_id"] = run_id
        log_message["test_count"] = test_count
        log_message["results"] = results
        log_message["summary"] = summary
        log_message["start_time"] = start_time
        log_message["end_time"] = end_time
        log_message["duration"] = Chronic.parse(end_time) - Chronic.parse(start_time)
        log_message["pass_count"] = pass_count
        log_message["fail_count"] = fail_count

        JSON.generate log_message
      rescue => e
        puts e
      end

    end





  end


end