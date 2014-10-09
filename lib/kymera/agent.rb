require_relative 'actor'

module Kymera

  class Agent

    attr_reader :actors, :results, :tests
    def initialize(actor_count = Kymera::processor_count)
      @actor_count = actor_count
      @actors = []
      start_actors(@actor_count)
      @tests = []
      @threads = []
    end

    def run_tests(tests, options)
      raise 'There were no tests passed in' if tests.empty? || tests == ''
      @results = ''
      @tests = tests
      @actors.each do |actor|
        _tests = @tests.shift(2)
        break if _tests.nil? || _tests == ''
        @threads << Thread.new(tests, options){ |tst, opt|
          result = actor.run_tests(tst, opt)
          @results << result
        }

      end

      until @tests.nil? || @tests.empty? do
        unless thread_limit?
          unless get_available_actors.empty? || get_available_actors.nil?
            test = @tests.shift
            break if test.nil? || test == ''
            get_available_actors.each do |actor|
              @threads << Thread.new(test, options){|tst, opt|
                result = actor.run_tests(tst, opt)
                @results << result
              }
            end
          end
        end
      end

      @threads.each do |thread|
        thread.join
      end

      @results
    end


    def actors_available?
      get_available_actors != nil || !get_available_actors.empty?
    end

    private

    def start_actors(actor_count)
      count = 1
      begin
        1.upto(actor_count){ @actors << Actor.new("actor_#{Kymera::host_name}_#{count}", 2); count += 1}
        puts "Actors created."
      rescue => e
        puts e
      end

    end

    def get_available_actors
      @actors.select { |actor| !actor.is_active? }
    end

    def thread_limit?
      active_thread_count >= @actor_count
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

  end






end