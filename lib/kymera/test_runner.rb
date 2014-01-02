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
      $stdout << "#{@thread_max}\n"
      1.upto(@thread_max) {
        count +=1
        $stdout << "#{count}\n"

        test = @tests.shift
        break if test.nil?
        options = @options << test
        @threads << Thread.new(options) { |opt| "bundle exec #{Cucumber::Cli::Main.new(opt).execute!}"}

      }

      #$stdout << "This is the @tests variable: #{@tests}\n"

      #until @tests.empty?
      #  while !thread_limit?
      #    options = @options + ' ' + @tests.shift
      #    $stdout << "\nNumber of current threads: #{active_thread_count}"
      #    $stdout << "\nNumber of threads: #{@threads.count}"
      #    $stdout << "\nTests empty? #{@tests.empty?}\n"
      #    $stdout << "Threads at their limit? #{thread_limit?}"
      #    @threads << Thread.new(options) { |opt| Cucumber::Cli::Main.new(opt).execute!} unless thread_limit?
      #  end
      #end

      @threads.each do |thread|
        thread.join
      end

      @threads.each do |thread|
        p thread
        puts thread.value
      end

      get_results

    end

    private

    def thread_limit?
      active_thread_count >= @thread_max
    end

    def active_thread_count
      count = 0
      @threads.each do |thread|

        if thread.alive?
          count =+ 1
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