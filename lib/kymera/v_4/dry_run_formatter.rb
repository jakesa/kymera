module Kymera
  module Cucumber
    class DryRunFormatter

      def initialize(step_mother, io, options)
        @io = io
      end

      def scenario_name(*args)
        #if args[0].include?("Outline")
        #  @scenario_name = args[2].split(':')[0]
        #else
        $stdout << args[2]
        $stdout << "\n"
        #end
      end

      #def before_table_row(*args)
      #
      #  args.each do |arg|
      #    unless arg.line < 1 || arg.send(:header?) == true
      #      $stdout << "#{@scenario_name + ":" + arg.line.to_s }"
      #      $stdout << "\n"
      #    end
      #
      #  end
      #end
    end
  end
end

