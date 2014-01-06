require 'cucumber'
module Kymera

  class Runner

    def initialize(tests, options)
      @options = options
      @tests = tests
      @thread_max = Kymera::processor_count * 2
      @threads = []
      ENV["AUTOTEST"] = "1" if $stdout.tty?
    end

    def run
      count = 0
      puts "Thread Max: #{@thread_max}"
      @comp_results = ''
      1.upto(@thread_max) {
        count +=1
        test = @tests.shift
        break if test.nil?

        @threads << Thread.new(test, @options) do |tst, opt|
          result = run_test(tst, opt)
          @comp_results += result
        end
      }
      run_queue
      clean_queue
      wait_for_threads
      @threads.each do |thread|
        puts "Waiting on thread: #{thread}"
        thread.join
        puts "Thread #{thread} finished"
      end

      #TODO: JS - This is a stub at the moment until I get real result handling implemented
      puts "#################################################################################################"
      puts "These are the final results"
      puts "#################################################################################################"
      #puts Kymera::ResultsParser.summarize_results(@comp_results)
      @comp_results
    end

    private

    def wait_for_threads
      puts "This is the main thread: #{Thread.main}"
      puts "This is the thread list: \n#{Thread.list}"
    end

    def run_test(test, options)
      results = ''
      _options = ''
      options.each do |option|
        _options += " #{option}"
      end
      puts "Running test: #{test}"
      io = IO.popen("bundle exec cucumber #{test} #{_options}")
      until io.eof? do
          result = io.gets
          #TODO: JS - the below piece of code should be triggered by some kind of parameter that is passed as runtime
          puts result
          results += result
      end
      Process.wait2(io.pid)
      results
    end

    def run_queue
      until @tests.empty? do
          unless thread_limit?
            test = @tests.shift
            puts "Run Queue remaining: #{@tests.count}"
            clean_queue
            @threads << Thread.new(test,@options) do |tst,opt|
              result = run_test(tst, opt)
              @comp_results << result
            end
          end
      end
    end

    def clean_queue
      @threads.delete_if {|t| !t.alive? }
    end


    def thread_limit?
      active_thread_count >= @thread_max
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

    def get_results
      results =[]
      @threads.each do |thread|
        results << thread.value
      end
      results
    end

  end

end