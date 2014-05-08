require_relative 'platform_utils'
require_relative 'test_parser'
require_relative 'test_runner'

module Kymera

  class Cli

    def initialize(tests, options, runner_options={})
      @tests = tests
      @options = options.split(',')
      @runner_options = runner_options
      #This is a registers the requesting machine with the Node network.  When done in this way, no actors will be registerd for this machine. This will throw an exception
      #if the proper setup has not been preformed.
      #Kymera::Node.register_node if @runner_options[:distributed]

    end

    def execute
      tests = Kymera::TestParser.new(@tests, @options).parse_tests

      #start_time = Time.now
       @results = Kymera::Runner.new(tests, @options, @runner_options).run
      #while t.alive?
      #  $stdout << "\rRun time(#{(Time.now - start_time).gmtime.strftime('%T')}"
      #end
      #t.join
      $stdout << @results
    end

  end


end