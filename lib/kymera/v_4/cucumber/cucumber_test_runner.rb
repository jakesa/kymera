require 'cucumber'
module Kymera
  module Cucumber
    class Runner

      #This is the test runner. It is responsible for the actual running of the test.  It takes in 3 parameters. The first being options(Array). These are the options to be used
      #for the cucumber test run. The run_id(String), this is a unique id identifying the test run that this test is for.  It is used as the channel name for publishing results
      #on the results bus.  And lastly results_bus(SSocket), this is a socket object representing the results bus. This is what is used for publishing results to that bus
      def initialize(options, run_id, result_bus = nil)
        @options = options
        @result_bus = result_bus
        @run_id = run_id
        ENV["AUTOTEST"] = "1" if $stdout.tty?
      end

      #This is kicking off the test. Takes in 3 parameters, test(String) is the test to be executed. options(Array) is an array of the options to be used with this test run. By default,
      #it uses the options passed in with the constructor. run_id(String) is the id of test run that this test is associated with. This is also defaulted with what was passed in
      #with the constructor
      def run_test(test, branch, options = @options, run_id = @run_id)
        _results = ''
        _options = ''
        options.each do |option|
          _options += " #{option}"
        end

        switch_to_branch(branch)

        puts "Running test: #{test}"
        io = Object::IO.popen("bundle exec cucumber #{test} #{_options}")
        until io.eof? do
          result = io.gets
          unless @result_bus.nil?
            @result_bus.publish_message(run_id, result)
          end
          _results += result
        end
        Process.wait2(io.pid)
        _results
      end

      private

      #TODO - add support for git
      #The worker machines have to be setup for public/private key authentication with hg. Otherwise, this will lockup the system waiting for a password
      def switch_to_branch(branch)
        io = Object::IO.popen('hg branch')
        current_branch = io.gets.chomp
        if current_branch == branch
          update_current_branch
        else
          output = ''
          io = Object::IO.popen("hg update #{branch}")
          until io.eof?
            output << io.gets
          end
          Process.wait2(io.pid)
          puts output
          update_current_branch
        end
      end

      def update_current_branch
        output = ''
        io = Object::IO.popen("hg pull -b . -u")
        until io.eof?
          output << io.gets
        end
        Process.wait2(io.pid)
        puts output
      end

    end
  end


end