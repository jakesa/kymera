require_relative '../../lib/kymera/v_2/socket_controller'

controller = Kymera::SocketController.new

push_socket = controller.create_push_socket('tcp://*:5556')
pull_socket = controller.create_pull_socket('tcp://127.0.0.1:5556')

threads = []

threads << Thread.new {

  10.times do
    puts "sending message"
    push_socket.send_string('Hello')
    sleep 3
  end
}

threads << Thread.new{
  10.times do
    data = ''
    pull_socket.recv_string(data)
    puts "received message #{data}"
  end
}

threads.each do |thread|
  thread.join
end