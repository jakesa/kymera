require 'ffi-rzmq'

def error_check(rc)
  if ZMQ::Util.resultcode_ok?(rc)
    false
  else
    STDERR.puts "Operation failed, [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    caller(1).each { |callstack| STDERR.puts(callstack)}
  end
end



reply_context = ZMQ::Context.new(1)
STDERR.puts "Failed to create a Context" unless reply_context
#------------Reply Socket----------------
Thread.new do

  reply_socket = reply_context.socket(ZMQ::REP)
  rc = reply_socket.bind('tcp://127.0.0.1:5555')

  error_check(rc)
  puts "Starting server"

  request =''
  while true
    puts 'waiting..'
    break if error_check(reply_socket.recv_string(request))

    puts "Received reqest: #{request}"

    break if error_check(reply_socket.send_string('World'))
    sleep 1
  end


  reply_socket.close
#-----------------------------------------
end

puts "Connecting to socket"

#-------------------------Request Socket
rq_context = ZMQ::Context.new(1)
rq_socket = rq_context.socket(ZMQ::REQ)
rc = rq_socket.connect("tcp://127.0.0.1:5555")
error_check(rc)

0.upto(10) do |num|
  puts "Sending request #{num}"

  break if error_check(rq_socket.send_string "Hello")

  rep = ''

  break if error_check(rq_socket.recv_string(rep))

  puts "Received reply #{rep}"

end

#----------------------------------------


rq_socket.close