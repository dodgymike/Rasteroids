require 'lib/game_entity.rb'
require 'lib/bullet.rb'
require 'chipmunk'

class Player < GameEntity
  COLLISION_NAME = :player

  attr_accessor :score
  attr_accessor :lives

  def initialize(image_name, width, height, space, max_x_coord, max_y_coord, scale)
    super(image_name, width, height, space, max_x_coord, max_y_coord, scale)

    @score = 0
    @lives = 10
  end

  def collision_name
    COLLISION_NAME
  end

  def shoot
    bullet = Bullet.new self, "media/bullet.bmp", 16, 16, @space, @max_x_coord, @max_y_coord, @scale

    bullet_angle = -@shape.body.a + Math::PI / 2
    bullet_speed = 100 * @scale

    bullet.shape.body.v = (CP::Vec2.new(Math.sin(bullet_angle) * bullet_speed, Math.cos(bullet_angle) * bullet_speed))
    bullet.shape.body.p = @shape.body.p + bullet.shape.body.v
    bullet.shape.body.a = @shape.body.a

    bullet
  end
end