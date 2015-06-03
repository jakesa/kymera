require 'ffi-rzmq'
require_relative 'kymera/szmq/szmq'
# require_relative 'kymera/cucumber/cucumber_test_runner'
require_relative 'kymera/v2/cucumber/cucumber_test_runner'
# require_relative 'kymera/worker'
# require_relative 'kymera/broker'
require_relative 'kymera/client'
# require_relative 'kymera/cucumber/test_parser'
require_relative 'kymera/v2/cucumber/test_parser'
require_relative 'kymera/results_bus'
require_relative 'kymera/platform_utils'
require_relative 'kymera/test_results_collector'
# require_relative 'kymera/cucumber/cucumber_results_parser'
require_relative 'kymera/v2/cucumber/cucumber_results_parser'
# require_relative '../lib/kymera/cucumber/cucumber_html_parser'
require_relative '../lib/kymera/v2/cucumber/cucumber_html_parser'
require_relative 'kymera/config/config'
require_relative 'kymera/array_exten'
require_relative '../lib/kymera/v2/worker_v2'
require_relative '../lib/kymera/v2/registry'
require_relative '../lib/kymera/v2/node'
require_relative '../lib/kymera/v2/broker'

module Kymera

  # Start a test run
  def self.run_tests(tests, test_runner, options, branch, grouped = false, real_time = true)
    Kymera::Client.new(real_time).run_tests(tests, test_runner, options, grouped, branch)

  end

  # Start the test broker
  def self.start_broker
    Kymera::Broker.new.start_broker
  end

  # Start a worker
  def self.start_worker
    Kymera::Worker.new.listen
  end

  # Start the results collector
  def self.start_collector
    Kymera::TestResultsCollector.new.listen
  end

  # Start the results bus
  def self.start_bus
    Kymera::ResultsBus.new.start_bus
  end

  # Generate the default config.yaml file
  def self.generate_config
    require 'yaml'
    puts "Generating congfig.yaml"
    config_options = {
        "client" => {
            "broker_address" => 'tcp://127.0.0.1:5550',
            "results_bus_address" => 'tcp://127.0.0.1:7001'
        },
        "broker" =>{
            "client_listening_port" => '5550',
            "worker_listening_port" => '5552',
            "internal_worker_port" => '5551',
            "number_of_connections" => '20'

        },
        "worker" => {
            'broker_address' => 'tcp://127.0.0.1:5552',
            'result_collector_address' => 'tcp://127.0.0.1:5556',
            'result_bus_address' => 'tcp://127.0.0.1:7000'
        },
        'result_collector' =>{
            'inc_listening_port' => '5556',
            'result_bus_address' => 'tcp://127.0.0.1:7000',
            'send_mongo_results' => false,
            'mongodb_address' => '127.0.0.1',
            'mongodb_port' => 27017,
            'mongodb_database_name' => 'default_db',
            'mongodb_collection_name' => 'default_collection'

        },
        'result_bus' => {
            'pub_port' => '7000',
            'sub_port' => '7001'
        }
    }
    config_file = File.open(File.join(Dir.pwd, '/kymera_config.yaml'), 'w+')
    config_options.to_yaml.split('\n').each do |line|
      config_file.write(line)
    end
    config_file.close
    config_options.to_yaml
  end
end