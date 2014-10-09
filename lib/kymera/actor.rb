
module Kymera

  class Actor

    attr_accessor :id, :results, :process_count, :tests

    def initialize(id, process_count, output = false, tests = [])
      @id = id
      @process_count = process_count
      @threads = []
      @results = ''
      @tests = tests
      @output = output
    end

    def is_active?
      active_thread_count > 0
    end

    def run_tests(tests, options)
      #puts "These are the tests: #{tests}"
      @results = '' #This is to reset the results for multiple runs on this actor

      puts "Tests passed in: #{tests}"

      if tests.nil? or tests == ''
        raise "There were no tests passed in."
      end
      if tests.is_a? Array
        if tests.empty?
          raise "There were no tests passed in."
        end
      end

      @tests = tests

      1.upto(process_count){
        test = @tests.pop
        break if test.nil?
        @threads << Thread.new(test, options){|tst, opt|
          result = run_test(tst, opt)
          @results << result
        }
      }

      run_queue(@tests, options)

      @threads.each do |thread|
        thread.join
      end
      results
    end


    private

    def run_test(test, options)
      _results = ''
      _options = ''
      options.each do |option|
        _options += " #{option}"
      end

      puts "Running test: #{test}"
      io = Object::IO.popen("bundle exec cucumber #{test} #{_options}")
      until io.eof? do
        result = io.gets
        #TODO: JS - the below piece of code should be triggered by some kind of parameter that is passed as runtime
        puts result if @output
        _results += result
      end
      Process.wait2(io.pid)
      _results
    end

    def run_queue(tests, options)
      until tests.empty? do
        unless thread_limit?
          test = tests.shift
          puts "Actor Run Queue remaining: #{tests.count}"
          #clean_queue
          @threads << Thread.new(test, options, @results) do |tst,opt, _results|
            result = run_test(tst, opt)
            _results << result
          end
        end
      end
    end

    def thread_limit?
      active_thread_count >= @process_count
    end

    def active_thread_count
      count = 0
      @threads.each do |thread|
        if thread.alive?
          count += 1
        end
      end
      count
    end

    def clean_queue
      @threads.delete_if {|t| !t.alive? }
    end

  end
end