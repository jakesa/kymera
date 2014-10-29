module Kymera
  module Cucumber
    class ResultsParser

      #TODO: JS - Add support for detecting skipped/undefined steps
      def self.parse
        @results
      end

      def self.summarize_results(results)
        results_array = results.split("\n")
        sort_order = %w[scenario step]
        aggregate_results = sort_order.map do |group|
          r_group_results = results_array.select {|l| l2 = l.scan(/^\d+ #{group}/); !l2.empty?}
          sum_up_lines(r_group_results, group)
        end.compact.join("\n")
        aggregate_results << "\n#{sum_up_failed_scenarios(results_array)}"
      end

      def self.sum_up_lines(lines, group)
        r_lines =[]
        lines.each do |l|
          r_lines << l.gsub('(','').gsub(')','')
        end

        _group, group_count, passed, passed_count, failed, failed_count = ''

        group_lines = r_lines.map {|m| m.scan(/(\d+) (#{group})/)}
        _group, group_count = count(group_lines) unless group_lines.empty?

        failed_scenarios = r_lines.map {|m| m.scan(/(\d+) (failed)/)}
        failed_scenarios.delete_if {|l| l.empty?}
        failed, failed_count = count(failed_scenarios) unless failed_scenarios.empty?

        passed_scenarios = r_lines.map {|m| m.scan(/(\d+) (passed)/)}
        passed_scenarios.delete_if {|l| l.empty?}
        passed, passed_count = count(passed_scenarios) unless passed_scenarios.empty?

        if group_count > 1
          _group += 's'
        end

        if failed_scenarios.empty?
          "#{group_count} #{_group} (\e[32m#{passed_count} #{passed}\e[0m)"
        elsif passed_scenarios.empty?
          "#{group_count} #{_group} (\e[31m#{failed_count} #{failed}\e[0m)"
        else
          "#{group_count} #{_group} (\e[31m#{failed_count} #{failed}\e[0m, \e[32m#{passed_count} #{passed}\e[0m)"
        end
      end

      def self.count(lines)
        count = 0
        word = ''
        lines.each do |l|
          count += l[0][0].to_i
          word = l[0][1]
        end
        [word, count]
      end

      def self.sum_up_failed_scenarios(results)
        results = results.select{|l| l.include?('[31mcucumber')}
        if results.empty?
          ''
        else
          results.map {|l| l << "\n"}
          formatted_results = "\e[31mFailing Scenarios:\n"
          results.each {|l| formatted_results << l}
          formatted_results << "\e[0m"
          formatted_results
        end
      end
    end

  end

end