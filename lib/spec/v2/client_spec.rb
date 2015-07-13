require_relative '../../../lib/kymera'
require 'pry'

describe Kymera::Client do


  it 'should start a test run' do
    context = Kymera::SZMQ.new
    registry = Kymera::Registry.new('localhost', 27017, 'kymera', 'nodes')
    config = Kymera::Config.new
    node = Kymera::Node.new(config)
    sleep 1
    node.register_node
    node.listen
    broker = Kymera::Broker.new(config, context, registry)
    broker.listen
    sleep 1
    client = Kymera::Client.new
    results = client.run_tests('~/apollo/source/integration_tests/features/login_and_session/login.feature', 'cucumber', ['-p default'], 'develop')
    # node.shutdown_node
    broker.shutdown
    expect(results).to eq true

  end

  it 'should start a test run with just the client' do
    client = Kymera::Client.new
    results = client.run_tests('~/apollo/source/integration_tests/features/login_and_session/login.feature', 'cucumber', ['-p default'], 'develop')
    # results = client.run_tests('~/apollo/source/integration_tests/features/login_and_session', 'cucumber', ['-p default'], 'develop', true)
    # results = client.run_tests('~/apollo/source/integration_tests/features/posting/list/postList_group_view.feature', 'cucumber', ['-p default'], 'develop', true)
    expect(results).to eq true
  end



end