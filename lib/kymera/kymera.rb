require_relative 'platform_utils'
require_relative 'test_parser'
require_relative 'test_runner'

module Kymera

  class Cli

    def initialize(tests, options)
      @tests = tests
      @options = options.split(',')
    end

    def execute
      tests = Kymera::TestParser.new(@tests, @options).parse_tests
      results = Kymera::Runner.new(tests, @options).run
      $stdout << results
    end



  end


end