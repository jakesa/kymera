require 'celluloid'
require_relative 'actor'

module Kymera

  #This class is for setting up the group of actors to be used per machine.
  class ActorGroup < Celluloid::SupervisionGroup
    pool Actor, as: :actor_pool, args: ['actor_pool', Celluloid.cores]
  end

end