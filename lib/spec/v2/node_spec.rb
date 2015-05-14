require_relative '../../../lib/kymera'
require 'pry'

describe Kymera::Node do

  # after :each do
  #   if node
  #     node.shutdown_node
  #   end
  # end


  it "should initialize with defaults" do
    node = Kymera::Node.new(Kymera::Config.new)
    expect(node.host_name).not_to eq nil
    expect(node.num_of_workers).not_to eq nil
    expect(node.port).to_not eq nil
    expect(node.registered).to eq false
    node.shutdown_node
  end

  it "should give back system information" do
    node = Kymera::Node.new(Kymera::Config.new)
    expect(node.system[:node_id]).to_not eq nil
    expect(node.system[:ip_address]).to_not eq nil
    expect(node.system[:port]).to_not eq nil
    expect(node.system[:processor_count]).to_not eq nil
    expect(node.system[:node_os]).to_not eq nil
    expect(node.system[:ruby_version]).to_not eq nil
    node.shutdown_node
  end

  it "should start workers" do
    node = Kymera::Node.new(Kymera::Config.new)
    #there is a race condition on startup with the workers getting to a ready status
    # sleep 1
    expect(node.worker_status[:dead]).to eq 0
    node.shutdown_node
  end

  it 'should return the worker status' do
    node = Kymera::Node.new(Kymera::Config.new)
    # sleep 1
    expect(node.worker_status.class).to eq Hash
    expect(node.worker_status.keys).to include :alive
    expect(node.worker_status.keys).to include :dead
    node.shutdown_node
  end

  it 'should shut down the node' do
    node = Kymera::Node.new(Kymera::Config.new)
    # sleep 1
    node.shutdown_node
    expect(node.worker_status[:alive]).to eq 0
  end

  it 'should restart the workers' do
    node = Kymera::Node.new(Kymera::Config.new)
    # sleep 1
    node.restart_workers
    # sleep 5
    expect(node.worker_status[:dead]).to eq 0
    node.shutdown_node
  end

  it 'should configure the node' do
    # pending
  end

  it 'should register the node' do
    node = Kymera::Node.new(Kymera::Config.new)
    node.register_node
    expect(node.registered).to eq true
    node.shutdown_node
  end

  it 'should unregister node' do
    node = Kymera::Node.new(Kymera::Config.new)
    node.register_node
    expect(node.registered).to eq true
    node.unregister_node
    expect(node.registered).to eq false
    node.shutdown_node
  end

  it 'should listen for messages on the bus' do
    # puts "starting node"
    node = Kymera::Node.new(Kymera::Config.new)
    # puts "starting to listen"
    node.listen
    result = false
    # sleep 5
    context = Kymera::SZMQ.new
    socket = context.socket("tcp://127.0.0.1:7000", "pub")
    socket.connect
    t = Thread.new(result) {
      ctx = Kymera::SZMQ.new
      sub_socket = ctx.socket("tcp://127.0.0.1:7001", "sub")
      # puts "waiting for reply"
      sub_socket.subscribe("test") {|channel, message|
        # puts "got reply"
        # puts channel
        # puts message
        result = true
        Thread.kill(Thread.current)
      }

    }
    sleep 1
    # puts "sending"
    # puts "message: #{JSON.generate({:test => {:run_id=>"this"}})}"
    # puts "on: #{Kymera.host_name}"
    # sleep 4
    socket.publish_message(Kymera.host_name, JSON.generate({:test => {:run_id=>"test"}}))
    t.join(10)
    expect(result).to eq true
    node.shutdown_node
  end

  it 'should accept a test run' do
    context = Kymera::SZMQ.new
    node = Kymera::Node.new(Kymera::Config.new)
    node.listen
    socket = context.socket("tcp://127.0.0.1:7000", "pub")
    socket.connect
    @results = false
    t = Thread.new(socket) { |p_socket|
      ctx = Kymera::SZMQ.new
      sub_socket = ctx.socket("tcp://127.0.0.1:7001", "sub")
      # puts "waiting for reply"
      sub_socket.subscribe("test") {|channel, message|
        # puts "got reply"
        # puts channel
        # puts message
        message = JSON.parse message
        if message.keys.include? "config"
          puts message
          puts "Sending test..."
          test = JSON.generate({:test_run => {:test => ['~/apollo/source/integration_tests/features/login_and_session/login.feature:9'], :runner => "cucumber", :options => ['-p default'], :run_id => "test"}})
          puts test
          p_socket.publish_message(Kymera.host_name, test)
        elsif message.keys.include? "results"
          puts message["results"]["text"]
          @results = true
          sub_socket.close
          Thread.kill(Thread.current)
        end
      }

    }
    sleep 1
    message = JSON.generate ({:config => {:branch => "default", :run_id => 'test'}})
    puts "sending config..."
    socket.publish_message(Kymera.host_name, message)
    puts "Sending test run..."
    t.join(90)
    socket.close
    expect(@results).to eq true
  end


end