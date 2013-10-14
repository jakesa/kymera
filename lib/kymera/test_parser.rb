module Kymera

  class TestParser

    def initialize(tests)
      @tests = tests
    end

    def parse_tests
        tests = dry_run(["cucumber",options[:files] , '--dry-run -f DryRunFormatterByExample', cucumber_opts(options[:test_options])].compact.join(" ")).split("\n")
        refined_tests =[]
        tests.delete_at(0) if tests[0].downcase.include?('using')
        tests.each do |test|
          refined_tests << test.gsub('\\','/')
        end
        $stdout << "The number of scenarios found to be executed: #{refined_tests.count}"
        $stdout << "\n"
        refined_tests
    end
  end
end