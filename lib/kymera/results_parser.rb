module Kymera

  class ResultsParser

    def self.parse
      @results
    end

    #JS - The below code is taken from Parallel Tests written by Michael Grosser
    def self.summarize_results(results)
      results_array = results.split("\n")
      scenarios = []
      steps = []
      failed = []
      undefined = []
      skipped = []
      pending = []
      passed = []
      results_array.each do |l|

      end
      sort_order = %w[scenario step failed undefined skipped pending passed]

      %w[scenario step].map do |group|
        group_results = results.grep /^\d+ #{group}/
        next if group_results.empty?

        sums = sum_up_results(group_results)
        sums = sums.sort_by { |word, _| sort_order.index(word) || 999 }
        sums.map! do |word, number|
          plural = "s" if word == group and number != 1
          "#{number} #{word}#{plural}"
        end
        "#{sums[0]} (#{sums[1..-1].join(", ")})"
      end.compact.join("\n")
    end

    def self.sum_up_results(results)
      results = results.join(' ').gsub(/s\b/,'') # combine and singularize results
      counts = results.scan(/(\d+) (\w+)/)
      sums = counts.inject(Hash.new(0)) do |sum, (number, word)|
        sum[word] += number.to_i
        sum
      end
      sums
    end

  end

end