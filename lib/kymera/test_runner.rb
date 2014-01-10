require 'cucumber'
module Kymera

  class Runner

    def initialize(tests, options, k_options)
      @options = options
      @k_options = k_options
      @tests = tests
      @thread_max = Kymera::processor_count * 2
      @threads = []
      ENV["AUTOTEST"] = "1" if $stdout.tty?
      @start_time = Time.now
    end

    def run
      #count = 0
      puts "Thread Max: #{@thread_max}"
      @comp_results = ''
      @test_groups = []
      puts "Group size: #{group_size}"
      group_tests
      run_locally
      #run_queue
      run_group_queue
      clean_queue
      @threads.each do |thread|
        #puts "Waiting on thread: #{thread}" #debugging
        thread.join
        #puts "Thread #{thread} finished" #debugging
      end
      report_results

    end

    private

    def report_results
      puts "#################################################################################################"
      puts "Results"
      puts Kymera::ResultsParser.summarize_results(@comp_results)
      report_time_taken
    end


    def group_tests
      until @tests.empty?
        test_group = @tests.pop(group_size)
        @test_groups << test_group
      end
    end

    def group_size
      size = (@tests.count/@thread_max)
      if size < 1
        size = 1
      elsif size == 1
        size = 2
      elsif size > 5
        size = 5
      end
      size
    end

    def run_locally
      1.upto(@thread_max){
        tests = @test_groups.pop
        break if tests.nil?
        @threads << Thread.new(tests, @options){|_tests, options|
          results = ''
          _tests.each do |test|
            result = run_test(test, options)
            results += result
          end
          @comp_results += results
        }
      }
    end

    def run_distributed
      1.upto(@thread_max) {
        count +=1
        test = @tests.shift
        break if test.nil?

        @threads << Thread.new(test, @options) do |tst, opt|
          result = run_test(tst, opt)
          @comp_results += result
        end
      }
    end

    def report_time_taken
      run_time = ((Time.now - @start_time)/60).to_s.match(/(\d+.\d{2})/)[0]
      puts "Took #{run_time}m"
    end

    #JS - This is a debugging method
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
          #puts result
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


    def run_group_queue
      until @test_groups.empty? do
        unless thread_limit?
          tests = @test_groups.shift
          puts "Run Queue remaining: #{@test_groups.count}"
          clean_queue
          @threads << Thread.new(tests, @options){|_tests, options|
            results = ''
            _tests.each do |test|
              result = run_test(test, options)
              results += result
            end
            @comp_results += results
          }
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