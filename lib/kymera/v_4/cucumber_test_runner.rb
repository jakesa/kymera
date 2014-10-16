require 'cucumber'
module Kymera
  module Cucumber
    class Runner
      def initialize(options)
        @options = options
        ENV["AUTOTEST"] = "1" if $stdout.tty?
      end

      def run_test(test, options = @options)
        _results = ''
        _options = ''
        options.each do |option|
          _options += " #{option}"
        end

        puts "Running test: #{test}"
        io = Object::IO.popen("bundle exec cucumber #{test} #{_options}")
        until io.eof? do
          result = io.gets
          #puts result
          #a publish to the results bus here would give the real-time results
          _results += result
        end
        Process.wait2(io.pid)
        _results
      end

    end
  end


end