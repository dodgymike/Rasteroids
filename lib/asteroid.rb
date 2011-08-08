require File.expand_path(File.dirname(__FILE__) + '/game_entity.rb')

class Asteroid < GameEntity
  def collision_name
    :asteroid
  end
end