
module Kymera
  module Cucumber
    class HTMLResultsParser
      def self.to_html(results)
        html_results = ''
        results_array = results.split("\n")
        results_array.each do |line|
          if line.start_with?("Using")
            if html_results == ''
              html_results << "<div class='feature'>"
              html_results << "<p>"
              html_results << "#{line}"
            else
              html_results << "</p></div>"
              html_results << "<div class='feature'>"
              html_results << "<p>"
              html_results << "#{line}"
            end
          else
            #\e[36m blue
            #\e[90m gray
            #\e[31m red
            #\e[32m green
            #\e[0m
            line.gsub!("\e[36m", "<span class='skip'>")
            line.gsub!("\e[90m", "<span class='text'>")
            line.gsub!("\e[31m", "<span class='error'>")
            line.gsub!("\e[32m", "<span class='pass'>")
            line.gsub!("\e[1m", "<span class='example'>")
            line.gsub!("\e[0m", "</span>")
            line.gsub!("[36m", "<span class='skip'>")
            line.gsub!("[90m", "<span class='text'>")
            line.gsub!("[31m", "<span class='error'>")
            line.gsub!("[32m", "<span class='pass'>")
            line.gsub!("[1m", "<span class='example'>")
            line.gsub!("[0m", "</span>")
            html_results << "#{line}<br/>"

          end
        end
        html_results
      end
    end
  end
end

