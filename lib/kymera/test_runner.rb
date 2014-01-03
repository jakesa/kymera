require 'cucumber'
module Kymera

  class Runner

    def initialize(tests, options)
      @options = options
      @tests = tests
      @thread_max = Kymera::processor_count * 2
      @threads = []

    end

    def run
      #The below is debugging code
      #$stdout << "\nMax threads: #{@thread_max}\n"
      #$stdout << "Options: #{@options}\n"
      #$stdout << "Tests: #{@tests}\n"
      #$stdout << "Output: #{@options + ' ' + @tests.shift}\n"
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

      @threads.each do |thread|
        thread.join
      end

      #TODO: JS - This is a stub at the moment until I get real result handling implemented
      puts "#################################################################################################"
      puts "These are the final results"
      puts "#################################################################################################"
      puts @comp_results

    end

    private

    def run_test(test, options)
      results = ''
      _options = ''
      options.each do |option|
        _options += " #{option}"
      end

      io = IO.popen("bundle exec cucumber #{test} #{_options}")

      until io.eof? do
        result = io.gets
        #puts result
        results += result
      end
      results
    end

    def run_queue
      until @tests.empty? do
          unless thread_limit?
            puts "Run Queue"
            test = @tests.shift
            @threads << Thread.new(test,@options) do |tst,opt|
              result = run_test(tst, opt)
              @comp_results << result
            end
          end
      end
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