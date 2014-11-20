require_relative '../../lib/kymera'

message = JSON.generate({name: "test"})

Kymera::MongoDriver.log_results(message)