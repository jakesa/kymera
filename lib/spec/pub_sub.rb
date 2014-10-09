require 'ffi-rzmq'


def error_check(rc)
  if ZMQ::Util.resultcode_ok?(rc)
    false
  else
    STDERR.puts "Operation failed, [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    caller(1).each { |callstack| STDERR.puts(callstack)}
  end
end


context = ZMQ::Context.new(1)
STDERR.puts "Failed to create a Context" unless context
#--------Publisher----------
Thread.new do
  pub_socket = context.socket(ZMQ::PUB)
  error_check(pub_socket.setsockopt(ZMQ::LINGER, 1))
  error_check(pub_socket.bind('tcp://127.0.0.1:2200'))

  string1 = []
  string2 = []
  string3 = ['Config', 'set your system to this branch']

  string1 << 'Test'
  string1 << 'this feature'
  string2 << 'Results'
  string2 << 'these are the results'

  loop do

    puts "Sending system config.."
    break if error_check(pub_socket.send_string(string3[0],ZMQ::SNDMORE))
    break if error_check(pub_socket.send_string(string3[1]))


    puts "Sending test.."
    break if error_check(pub_socket.send_string(string1[0],ZMQ::SNDMORE))
    break if error_check(pub_socket.send_string(string1[1]))

    puts "Sending results.."
    break if error_check(pub_socket.send_string(string2[0], ZMQ::SNDMORE))
    break if error_check(pub_socket.send_string(string2[1]))

    sleep 1
  end

  error_check(pub_socket.close)
  puts "Closing pub socket"
end

t = []
t << Thread.new do
  sub_socket = context.socket(ZMQ::SUB)
  error_check(sub_socket.setsockopt(ZMQ::LINGER, 1))
  error_check(sub_socket.connect('tcp://127.0.0.1:2200'))
  error_check(sub_socket.setsockopt(ZMQ::SUBSCRIBE,'Test'))

  10.times do |num|
    header = ''
    break if error_check(sub_socket.recv_string(header))
    body = ''
    rc = sub_socket.recv_string(body)
    break if error_check(rc)
    STDOUT << "Received message #{num}: #{header}:#{body}"
  end
  error_check(sub_socket.close)
end

t << Thread.new do
  $stdout << "Is this code even running?"
  sub_socket = context.socket(ZMQ::SUB)
  error_check(sub_socket.setsockopt(ZMQ::LINGER, 1))
  error_check(sub_socket.setsockopt(ZMQ::SUBSCRIBE,'Results'))
  error_check(sub_socket.connect('tcp://127.0.0.1:2200'))

  loop do
    header = ''
    break if error_check(sub_socket.recv_string(header))
    body = ''
    rc = sub_socket.recv_string(body) if sub_socket.more_parts?
    break if error_check(rc)
    STDOUT << "Received message: #{header}:#{body}"
  end
  error_check(sub_socket.close)
end


t << Thread.new do
  sub_socket = context.socket(ZMQ::SUB)
  puts sub_socket.methods
  error_check(sub_socket.setsockopt(ZMQ::LINGER, 1))
  error_check(sub_socket.connect('tcp://127.0.0.1:2200'))
  error_check(sub_socket.setsockopt(ZMQ::SUBSCRIBE,'Config'))

  10.times do |num|
    header = ''
    break if error_check(sub_socket.recv_string(header))
    body = ''
    rc = sub_socket.recv_string(body) if sub_socket.more_parts?
    break if error_check(rc)
    STDOUT << "Received message #{num}: #{header}:#{body}"
  end
  error_check(sub_socket.close)
end

t.each {|thread| thread.join}

context.terminate