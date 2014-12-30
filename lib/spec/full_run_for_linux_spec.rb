require_relative '../../lib/kymera'
threads = []

trap('INT') do
  threads.each do |thread|
    thread.kill
  end unless threads.empty?
  @close = true
end

#Results bus thread
threads << Thread.new {
  Kymera.start_bus
}

#Broker thread
threads << Thread.new {
  Kymera.start_broker
}

#Results collector thread
threads << Thread.new {
  Kymera.start_collector
}

threads << Thread.new {
  Kymera.start_worker
}
#
# threads << Thread.new {
#   Kymera.start_worker
# }
#
# threads << Thread.new {
#   Kymera.start_worker
# }

#give stuff a chance to start up
sleep 2

# Kymera.run_tests('~/apollo/source/integration_tests/features/posting/delete', 'cucumber', ['-p default'], 'develop', true)
Kymera.run_tests('~/apollo/source/integration_tests/features/login_and_session', 'cucumber', ['-p default'], 'develop', true)


loop do
  raise SystemExit if @close
end




