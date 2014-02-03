require 'celluloid'
require_relative 'actor'

module Kymera

  class ActorGroup < Celluloid::SupervisionGroup
    pool Actor, as: :actor_pool, args: ['actor_pool', Celluloid.cores]
  end

end