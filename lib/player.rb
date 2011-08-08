require File.expand_path(File.dirname(__FILE__) + '/game_entity.rb')

class Player < GameEntity
  def collision_name
    :player
  end
end