class Asteroid < GameEntity
  COLLISION_NAME = :asteroid

  def collision_name
    COLLISION_NAME
  end
end