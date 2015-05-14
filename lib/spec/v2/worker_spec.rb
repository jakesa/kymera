require_relative '../../../lib/kymera'
require 'pry'


describe Kymera::Worker do

  it 'should initialize with the worker id' do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new('worker_id_1', context)
    expect(worker.worker_id).to eq('worker_id_1')
  end

  it 'should initialize with registered set to false' do
    context = Kymera::SZMQ.new
    expect(Kymera::Worker.new('worker_id_1', context).registered).to_not eq(true)
  end

  it 'should initialize with a config object' do
    context = Kymera::SZMQ.new
    expect(Kymera::Worker.new('worker_id_1', context).config).to_not eq(nil)
  end

  it 'should reply to a request in JSON' do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    worker.listen
    socket = context.socket("inproc://worker", "request")
    socket.bind
    message = JSON.generate ({:test => "message"})
    reply = socket.send_message message
    socket.close
    expect(reply).to eq "test received"
  end

  it 'should accept a configuration request' do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    worker.listen
    socket = context.socket("inproc://worker", "request")
    socket.bind
    message = JSON.generate ({:config => {:branch => "default"}})
    reply = socket.send_message message
    socket.close
    expect(reply).to eq "done"
  end

  it 'should processes a test run request' do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    worker.listen
    socket = context.socket("inproc://worker", "request")
    socket.bind
    message = JSON.generate ({:config => {:branch => "default"}})
    test = JSON.generate({:test_run => {:test => '~/apollo/source/integration_tests/features/login_and_session/login.feature:9', :runner => "cucumber", :options => ['-p default'], :run_id => "jakesMacBook"}})
    puts "sending config..."
    socket.send_message message
    puts "Sending test run..."
    results = socket.send_message test
    socket.close
    expect(results).to_not eq nil
  end

  it 'should return a running test status ' do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    worker.listen
    socket = context.socket("inproc://worker", "request")
    socket.bind
    message = JSON.generate ({:config => {:branch => "default"}})
    test = JSON.generate({:test_run => {:test => '~/apollo/source/integration_tests/features/login_and_session/login.feature:9', :runner => "cucumber", :options => ['-p default'], :run_id => "jakesMacBook"}})
    puts "sending config..."
    socket.send_message message
    puts "Sending test run..."
    t = Thread.new(socket) {|s| s.send_message test }
    sleep 2
    results = worker.status
    t.join
    socket.close
    expect(results).to eq "running test"
  end

  it 'should be available for running tests if the worker is listening' do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    worker.listen
    socket = context.socket("inproc://worker", "request")
    socket.bind
    message = JSON.generate ({:stop => ""})
    # here to stop a race condition that was causing the test to fail
    sleep 1
    results = worker.available?
    socket.send_message(message)
    socket.close
    expect(results).to eq true
  end

  it "should not be available for running tests if the worker isnt listening" do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    expect(worker.available?).to eq false
  end

  it "should not be available for running tests after receiving a stop message" do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    socket = context.socket("inproc://worker", "request")
    socket.bind
    worker.listen
    message = JSON.generate ({:stop => ""})
    # here to stop a race condition that was causing the test to fail
    sleep 1
    results = worker.available?
    socket.send_message(message)
    socket.close
    expect(results).to eq true
    expect(worker.available?).to eq false
  end

  it "should be available for tests once again after being told to stop and then being restarted" do
    context = Kymera::SZMQ.new
    worker = Kymera::Worker.new("worker_id_1", context)
    worker.listen
    socket = context.socket("inproc://worker", "request")
    socket.bind
    message = JSON.generate ({:stop => ""})
    # here to stop a race condition that was causing the test to fail
    sleep 1
    results = worker.available?
    socket.send_message(message)
    expect(results).to eq true
    expect(worker.available?).to eq false
    worker.listen
    sleep 1
    socket.close
    expect(worker.available?).to eq true
  end

end