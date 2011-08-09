#!/usr/bin/ruby -w
# server

require 'drb'

require 'lib/player'
require 'lib/asteroid'
require 'lib/bullet'
require 'lib/game_entity'
require 'lib/game_server'

DRb.start_service 'druby://:9000', GameServer.new
puts DRb.uri

DRb.thread.join