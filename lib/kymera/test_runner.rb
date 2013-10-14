module Kymera

  class Runner

    def initialize(tests, task=nil)
      @tests = tests
      @thread_max = Kymera::processor_count * 2
      @threads = []
      @task = task
    end

    def run
      #@tests.each do |test|
      #  Kymera::wait_for {!thread_limit?}
      #  @threads << Thread.new(test) {|t| }
      #end
      #
      #@threads.each do |thread|
      #  thread.join
      #end

      1.upto(@thread_max) {
        @threads << Thread.new(@tests.shift) {|test| 'run test' }

      }

      until @tests.nil?
        
      end


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

  end

end