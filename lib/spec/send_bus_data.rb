require_relative '../../lib/kymera'

zmq = Kymera::SZMQ.new
#
pub_socket = zmq.socket('tcp://127.0.0.1:7000', 'pub')
pub_socket.connect
sleep 2
pub_socket.publish_message('broker', JSON.generate({:test_run => {:test => ['~/apollo/source/integration_tests/features/login_and_session/login.feature:9',
                                                                            '~/apollo/source/integration_tests/features/login_and_session/login.feature:13',
                                                                            '~/apollo/source/integration_tests/features/login_and_session/login.feature:17'],
                                                                  :runner => "cucumber",
                                                                  :options => ['-p default'],
                                                                  :sender_id => "test",
                                                                  :start_time => Time.now.to_s}}))

#context = ZMQ::Context.new
#socket = context.socket(ZMQ::PUB)
#socket.connect('tcp://127.0.0.1:7000')
#sleep 5
#socket.send_string('results', ZMQ::SNDMORE)
#socket.send_string('these are some more results')


