require_relative 'dry_run_formatter'

module Kymera

  module Cucumber
    class TestParser

      def initialize(tests, options)
        @tests = tests
        @options = options
      end

      def parse_tests
        tests = dry_run(["cucumber", @tests, '--dry-run -f DryRunFormatter', @options].compact.join(" ")).split("\n")
        refined_tests =[]
        tests.delete_at(0) if tests[0].downcase.include?('using')
        tests.each do |test|
          refined_tests << test.gsub('\\','/')
        end
        $stdout << "The number of scenarios found to be executed: #{refined_tests.count}"
        $stdout << "\n"
        refined_tests
      end

      private

      def dry_run(cmd)
        $stdout << "Preprocessing test files"
        $stdout << "\n"
        tr = Thread.new(cmd) { |c| `#{c}`}
        tr.join
        tr.value
      end
    end
  end
end