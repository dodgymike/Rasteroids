class Bullet < GameEntity
  COLLISION_NAME = :bullet
  def collision_name
    COLLISION_NAME
  end
end