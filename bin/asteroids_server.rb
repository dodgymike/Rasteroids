#!/usr/bin/env ruby -w
# server

require 'drb'
require 'lib/asteroid.rb'
require 'lib/bullet.rb'
require 'lib/game_entity.rb'
require 'lib/player.rb'

class GameServer
end

DRb.start_service nil, DistCalc.new
puts DRb.uri

DRb.thread.join