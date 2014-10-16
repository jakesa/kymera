require 'socket'

module Kymera

  def self.processor_count
    @processor_count ||= case RbConfig::CONFIG['host_os']
       when /darwin9/
         `hwprefs cpu_count`.to_i
       when /darwin/
         (hwprefs_available? ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
       when /linux|cygwin/
         `grep -c ^processor /proc/cpuinfo`.to_i
       when /(net|open|free)bsd/
         `sysctl -n hw.ncpu`.to_i
       when /mswin|mingw/
         require 'win32ole'
         wmi = WIN32OLE.connect("winmgmts://")
         cpu = wmi.ExecQuery("select NumberOfLogicalProcessors from Win32_Processor")
         cpu.to_enum.first.NumberOfLogicalProcessors
       when /solaris2/
         `psrinfo -p`.to_i # this is physical cpus afaik
       else
         $stderr.puts "Unknown architecture ( #{RbConfig::CONFIG["host_os"]} ) assuming one processor."
         1
     end
  end


  def self.ip_address
    ips = Socket.ip_address_list
    ip = ''
    ips.each do |i|
      ip = i.ip_address if i.ipv4? && i.ip_address.start_with?("10")
    end
    ip
  end



  def self.host_name
    Socket.gethostname
  end

  def self.wait_for(&block)
    found = false
    i = 0
    until i == 60 || found
      found = yield
      sleep 1
      i +=1
    end
    found
  end
end