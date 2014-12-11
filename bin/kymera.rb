#!/usr/bin/env ruby
require 'kymera'

args = ARGV
threads = []
trap ("INT") do
  puts "\nStopping Kymera processes..."
  threads.each do |thread|
    thread.kill
  end
end

if args.length > 1
  args.each do |arg|
    case arg
      when "broker"
        threads << Thread.new {Kymera.start_broker}
      when "bus"
        threads << Thread.new {Kymera.start_bus}
      when "collector"
        threads << Thread.new {Kymera.start_collector}
      when "worker"
        threads << Thread.new {Kymera.start_worker}
      when "config"
        threads << Thread.new {Kymera.generate_config}
      else
        threads.each do |thread|
          thread.kill
        end

        raise "No valid parameters were passed in. Here is a list of the valid parameters:
            broker\nbus\ncollector\nworker\nconfig\n"
    end
  end

else
  case args[0]
    when "broker"
      threads << Thread.new {Kymera.start_broker}
    when "bus"
      threads << Thread.new {Kymera.start_bus}
    when "collector"
      threads << Thread.new {Kymera.start_collector}
    when "worker"
      threads << Thread.new {Kymera.start_worker}
    when "config"
      threads << Thread.new {Kymera.generate_config}
    else
      threads.each do |thread|
        thread.kill
      end

      raise "No valid parameters were passed in. Here is a list of the valid parameters:
            broker\nbus\ncollector\nworker\nconfig\n"
  end

end


threads.each do |thread|
  thread.join
end

