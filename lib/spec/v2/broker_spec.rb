require_relative '../../../lib/kymera'
require 'pry'

describe Kymera::Broker do

  it 'should start with default values' do
    context = Kymera::SZMQ.new
    registry = Kymera::Registry.new('localhost', 27017, 'kymera', 'nodes')
    config = Kymera::Config.new
    node = Kymera::Node.new(config)
    p 1
    node.listen
    p 2
    broker = Kymera::Broker.new(config, context, registry)
    p 3
    broker.listen
    p 4
    sleep 1
    node.shutdown_node
    p 5
    broker.shutdown
    p 6
    sleep 10
    raise "It no work"
  end

  it "should accept and complete a test run" do
    context = Kymera::SZMQ.new
    registry = Kymera::Registry.new('localhost', 27017, 'kymera', 'nodes')
    config = Kymera::Config.new
    node = Kymera::Node.new(config)
    node.register_node
    node.listen

    broker = Kymera::Broker.new(config, context, registry)
    broker.listen
    sleep 3
    test = JSON.generate({:test_run => {:test => ['~/apollo/source/integration_tests/features/login_and_session/login.feature:9', '~/apollo/source/integration_tests/features/login_and_session/login.feature:13', '~/apollo/source/integration_tests/features/login_and_session/login.feature:17'], :runner => "cucumber", :options => ['-p default'], :sender_id => "test"}})

    socket = context.socket("tcp://127.0.0.1:7000", "pub")
    # socket.connect
    p 101
    sub_socket = context.socket("tcp://127.0.0.1:7001", "sub")
    p 102

    t = Thread.new(sub_socket) {|ssocket|

      ssocket.subscribe('test') {|channel, message|
      message = JSON.parse(message)
      puts message

      }
    }
    sleep 5
    socket.publish_message('broker', test)

    t.join(60)

  end


end