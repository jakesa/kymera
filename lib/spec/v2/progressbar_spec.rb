require_relative "../../../lib/kymera"


describe Kymera::Progress do

  it 'should work' do
    pb = Kymera::Progress.new(34)
    pb.increment(3, "pass")
    sleep 3
    15.times do
      pb.refresh
      sleep 1
    end
    pb.log("Working tests")
    sleep 1
    pb.log "waiting for tests to pass"
    sleep 1
    pb.increment(18, "fail")
    sleep 1
    pb.log("tests are failing")
    10.times do
      pb.refresh
      sleep 1
    end
    pb.increment(3, "warning")
    pb.log "tests are in a warning state"
    10.times do
      pb.refresh
      sleep 1
    end
    pb.increment(10, "pass")
    pb.log "tests are magically passing again"
  end

end