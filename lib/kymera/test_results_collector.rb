require_relative 'szmq/szmq'
require_relative 'mongo_driver'
require 'chronic'
require 'json'

module Kymera

  class TestResultsCollector

    def initialize
      @config = Kymera::Config.new
      @zmq = Kymera::SZMQ.new
      @out_socket = @zmq.socket(@config.result_collector["result_bus_address"], 'pub')
      @out_socket.connect
    end

    def listen
      puts "Test collector started..."
      @run_id = ''
      results = ''
      @inc_socket.receive do |message|
        parsed_message = JSON.parse message
        @run_id = parsed_message["run_id"]
        test_count = parsed_message["test_count"].to_i
        start_test_count = parsed_message["test_count"]
        runner = parsed_message["runner"]
        results << parsed_message["results"]
        start_time = parsed_message["start_time"]
        puts 'Results run started with the following configuration:'
        puts "Run ID: #{@run_id}"
        puts "Test count: #{test_count}"
        finalize_results(start_test_count, @run_id, results, runner, start_time)
      end

    end

    def finalize_results(test_count, run_id, results, runner, start_time)
      if runner.downcase == 'cucumber'

        puts test_count
        puts run_id
        puts results
        puts runner
        puts start_time

        begin
          puts "Summarizing results.."
          r_results = Kymera::Cucumber::ResultsParser.summarize_results(results)
          puts "Getting pass count..."
          pass_count = Kymera::Cucumber::ResultsParser.scenario_counts[:pass]
          puts "Getting fail count..."
          fail_count = Kymera::Cucumber::ResultsParser.scenario_counts[:fail]
          puts "Converting results to html..."
          html_results = Kymera::Cucumber::HTMLResultsParser.to_html(results)
          puts "Converting summary to html..."
          html_summary = Kymera::Cucumber::HTMLResultsParser.to_html(r_results)
          puts "Setting end time"
          end_time = Time.now
          puts "Starting database logging processes..."
          Kymera::MongoDriver.log_results(build_test_log(test_count, run_id, html_results, html_summary, start_time, end_time.to_s, pass_count, fail_count), @config.result_collector["mongodb_address"],
                                          @config.result_collector["mongodb_port"].to_i, @config.result_collector["mongodb_database_name"], @config.result_collector["mongodb_collection_name"])
          puts "Setting run id..."
        rescue => e
          puts "There was an error in the logging process:"
          puts e
          puts e.backtrace
        ensure
          run_id = "end_#{run_id}"
          puts "Sending results to client...#{run_id}"
          @out_socket.publish_message(run_id, r_results)
        end
      end
    end

    private


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