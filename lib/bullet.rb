class Bullet < GameEntity
  COLLISION_NAME = :bullet

  attr_accessor :player

  def initialize(player, image_name, width, height, space, max_x_coord, max_y_coord, scale)
    super(image_name, width, height, space, max_x_coord, max_y_coord, scale)

    @player = player
  end

  def collision_name
    COLLISION_NAME
  end
end