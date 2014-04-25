require 'cucumber'
require_relative 'actor'
require_relative 'config'
module Kymera

  class Runner

    def initialize(tests, cucumber_options, runner_options={})
      @options = cucumber_options
      @runner_options = runner_options
      @tests = tests
      @thread_max =  @runner_options[:max_thread_size].nil? ? Kymera::processor_count * 2 : @runner_options[:max_thread_size]
      ENV["AUTOTEST"] = "1" if $stdout.tty?
      @start_time = Time.now
      @actors = []
      if @runner_options[:distributed]
        @nodes = Kymera::Node.get_nodes
        #p "Those are the nodes that were returned #{@nodes}"
        raise "There appear to be no Nodes with Actors registered to the Node network" if @nodes.empty?
      else
        if @runner_options[:number_of_actors].nil?
          @actors << Actor.new("#{Kymera::host_name}", @thread_max)
        else
          count = 0
          @runner_options[:number_of_actors].to_i.times{@actors << Actor.new("#{Kymera::host_name}_#{count += 1}", @thread_max, false) }
        end
      end

      @test_groups = []
      @group_size = @runner_options[:group_size].nil? ? 0 : @runner_options[:group_size]
      @threads = []
    end

    def runner_options
      "group_size, max_thread_size, number_of_actors, distributed, output"
    end

    def run
      @comp_results = ''
      puts "Running tests with #{@actors.count} actors using #{@thread_max} processes per actor"
      if @group_size > 0
        puts "Group size: #{@group_size}"
        group_tests
        puts "Number of groups: #{@test_groups.count}"
        if @runner_options[:distributed]
          run_distributed(@test_groups, @options)
          #run_group_dist_queue(@test_groups, @options)
        else
          run_in_groups(@test_groups, @options)
          run_group_queue(@test_groups, @options)
        end
        #check_all_queues
        wait_for_threads
      else
        run_using_cell(@tests, @options)
      end


      #puts @comp_results
      report_results
      Kymera::Node.unregister_node if @runner_options[:distributed]
      close_actors unless @runner_options[:distributed]
    end

    private

    def report_results
      puts "######################################"
      puts "              Results"
      puts "######################################"
      puts Kymera::ResultsParser.summarize_results(@comp_results)
      report_time_taken
    end

    def close_actors
      @actors.each {|actor| actor.terminate}
    end


    def group_tests
      until @tests.empty?
        test_group = @tests.pop(@group_size)
        @test_groups << test_group
      end
    end

    def run_distributed(tests, options)
      count = 0
      #p @actors
      @nodes.each { |node|
        count +=1
        #p tests
        test = tests.shift
        #p test
        break if test.nil?
          @threads << Thread.new(test, options) do |tst, opt|
            puts "This is the test passed to the actor: #{tst}"
            result = node.run_tests(tst, opt)
            @comp_results += result
          end
      }
    end

    def run_in_groups(test_groups, options)
      count = 0
      1.upto(@actors.count){
        puts "This is the count: #{count}"
        tests = test_groups.pop
        break if tests.nil? || tests.empty?
        @threads << Thread.new(tests, options, count) {|tst, opt, ct|
          result = @actors[ct].run_tests(tst, opt)
          @comp_results << result
        }
        count += 1
      }
    end


    def run_using_cell(tests, options)
      results = @actors[0].run_tests(tests,options)
      @comp_results << results
    end

    def report_time_taken
      run_time = ((Time.now - @start_time)/60).to_s.match(/(\d+.\d{2})/)[0]
      puts "Took #{run_time}m"
    end

    def wait_for_threads
      #p @threads
      @threads.each {|t| t.join}
    end

    #def run_test(test, options)
    #  results = ''
    #  _options = ''
    #  options.each do |option|
    #    _options += " #{option}"
    #  end
    #  puts "Running test: #{test}"
    #  io = IO.popen("bundle exec cucumber #{test} #{_options}")
    #  until io.eof? do
    #      result = io.gets
    #      #TODO: JS - the below piece of code should be triggered by some kind of parameter that is passed as runtime
    #      #puts result
    #      results += result
    #  end
    #  Process.wait2(io.pid)
    #  results
    #end
    #
    #def run_queue
    #  until @tests.empty? do
    #      unless thread_limit?
    #        test = @tests.shift
    #        puts "Run Queue remaining: #{@tests.count}"
    #        clean_queue
    #        @threads << Thread.new(test,@options) do |tst,opt|
    #          result = run_test(tst, opt)
    #          @comp_results << result
    #        end
    #      end
    #  end
    #end
    #

    def run_group_queue(test_groups, options)

      until test_groups.empty? do
        unless get_available_actors.empty?
          get_available_actors.each do |actor|
            tests = test_groups.shift
            clean_queue
            @threads << Thread.new(tests, options){|_tests, _options|
              puts "Run Queue remaining: #{test_groups.count}"
              results = actor.run_tests(_tests, _options)
              @comp_results << results
            } unless tests.nil?
          end
        end
      end
    end

    def run_group_dist_queue(test_groups, options)
      until test_groups.empty? do
        unless get_available_dist_actors.empty?
          get_available_dist_actors.each do |actor|
            tests = test_groups.shift
            #clean_queue
            @threads << Thread.new(tests, options){|_tests, _options|
              puts "Run Queue remaining: #{test_groups.count}"
              results = actor.run_tests(_tests, _options)
              @comp_results << results
            } unless tests.nil?
          end
        end
      end
    end


    #TODO: JS-this is a work in progress. Its an attempt at optimizing test execution
    def check_all_queues
      puts "Checking queues..."
      until actors_not_running?
        available_actors = get_available_actors
        running_actors = get_still_running_actors
        available_actors.each do |actor|
          puts "These are the available actors: #{actors}"
          puts "These are the tests: #{running_actors.last.tests}"
          test = running_actors.pop.tests.pop
          puts "This is the test: #{test}"
          @threads << Thread.new {
            results = actor.run_tests(test, @options)
            @comp_results << results
          }unless test.nil?
        end unless running_actors.empty?
      end
    end

    def get_available_actors
      @actors.select {|actor| actor.tests.empty?}
    end

    def get_available_dist_actors
      actors = []
      @nodes.each do |node|
        node.actors.each {|actor| actors << node[actor] if node[actor].tests.empty}
      end
      actors
    end

    def get_still_running_actors
      @actors.select {|actor| puts actor.id; puts actor.tests;!actor.tests.empty?}
    end

    def actors_not_running?
      actors = []
      puts @actors
      @actors.each {|a| puts a.is_active?; actors << a.is_active?}
      puts actors
      puts actors.include? true
      !actors.include? true
    end

    def clean_queue
      @threads.delete_if {|t| !t.alive? }
    end


    #def thread_limit?
    #  active_thread_count >= @thread_max
    #end
    #
    #def active_thread_count
    #  count = 0
    #  @threads.each do |thread|
    #    if thread.alive?
    #      count += 1
    #    end
    #  end
    #  count
    #end

    #def get_results
    #  results =[]
    #  @threads.each do |thread|
    #    results << thread.value
    #  end
    #  results
    #end

  end


end