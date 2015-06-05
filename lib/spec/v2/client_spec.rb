require_relative '../../../lib/kymera'
require 'pry'

describe Kymera::Client do


  it 'should start a test run' do
    # results = false
    context = Kymera::SZMQ.new
    registry = Kymera::Registry.new('localhost', 27017, 'kymera', 'nodes')
    config = Kymera::Config.new
    node = Kymera::Node.new(config)
    # socket = context.socket("tcp://127.0.0.1:7000", "pub")
    # sub_socket = context.socket("tcp://127.0.0.1:7001", "sub")
    # socket.connect
    sleep 1
    # t = Thread.new(sub_socket) {|ssocket|
    #
    #   ssocket.subscribe('test') {|channel, message|
    #     message = JSON.parse(message)
    #     puts "Got results:"
    #     puts message
    #     results = true
    #     Thread.kill(Thread.current)
    #   }
    # }
    node.register_node
    node.listen

    broker = Kymera::Broker.new(config, context, registry)
    broker.listen
    sleep 1

    client = Kymera::Client.new
    results = client.run_tests('~/apollo/source/integration_tests/features/login_and_session/login.feature', 'cucumber', ['-p default'], 'develop')

    # test = JSON.generate({:test_run => {:test => ['~/apollo/source/integration_tests/features/login_and_session/login.feature:9',
    #                                               '~/apollo/source/integration_tests/features/login_and_session/login.feature:13',
    #                                               '~/apollo/source/integration_tests/features/login_and_session/login.feature:17'],
    #                                     :runner => "cucumber",
    #                                     :options => ['-p default'],
    #                                     :sender_id => "test",
    #                                     :start_time => Time.now.to_s}})
    # sleep 2
    # socket.publish_message('broker', test)
    # count = 0
    # while count < 60
    #   t.join(1)
    #   count +=1
    #   # p count
    # end

    expect(results).to eq true

  end



end