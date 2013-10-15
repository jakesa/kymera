module Kymera

  class Runner

    def initialize(task, tests)
      @task = task
      @tests = tests
      @thread_max = Kymera::processor_count * 2
      @threads = []
    end

    def run

      1.upto(@thread_max) {
        @threads << Thread.new(@tasks.shift) { |task| task.runner.run }

      }

      until @tests.nil?
        @threads << Thread.new(@tasks.shift) { |task| task.runner.run } unless thread_limit?
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