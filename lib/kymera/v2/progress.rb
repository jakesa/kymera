
module Kymera

  class Progress

    def initialize(test_count, real_time = false)
      if real_time
        @bar = ProgressBar.create(:title => "Progress", :starting_at => 0, :total => test_count, :format => '%t: %c/%C : %a <%B>' )
      else
        @bar = ProgressBar.create(:title => "Tests", :starting_at => 0, :total => test_count, :format => '%t: %C : %a' )
      end
      @color = $stdout.tty?
      @status = 'pass'
    end

    def refresh
      if @color
        colorize(@status) {@bar.refresh}
      else
        @bar.refresh
      end
    end

    def increment(num, status)
      if @color
        colorize(status) {@bar.progress += num}
      else
        @bar.progress += num
      end
      @status = status
    end

    def log(message)
      if @color
        colorize(@status) {@bar.log message}
      else
        @bar.log message
      end
    end

    private

    def colorize(status, &block)
      case status
      when 'pass'
        $stdout.print "\e[32m"
        yield
        $stdout.print "\e[0m"
      when 'fail'
        $stdout.print "\e[31m"
        yield
        $stdout.print "\e[0m"
      when 'warning'
        $stdout.print "\e[33m"
        yield
        $stdout.print "\e[0m"
      end
    end


  end
end