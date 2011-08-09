class Bullet < GameEntity
  COLLISION_NAME = :bullet

  attr :player

  def initialize(player, window, image_name, width, height, space, max_x_coord, max_y_coord, scale)
    super(window, image_name, width, height, space, max_x_coord, max_y_coord, scale)

    @player = player
  end

  def collision_name
    COLLISION_NAME
  end
end