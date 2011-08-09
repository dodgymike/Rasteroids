require 'lib/game_entity.rb'
require 'lib/bullet.rb'
require 'chipmunk'

class Player < GameEntity
  COLLISION_NAME = :player

  def collision_name
    COLLISION_NAME
  end

  def shoot
    current_time = Time.now.to_f

    if @last_bullet_time.nil? || !@last_bullet_time
      @last_bullet_time = current_time
    end

    if current_time - @last_bullet_time <= 0.300
      return nil
    end

    @last_bullet_time = current_time

    puts "last_bullet_time (#{@last_bullet_time})"

    bullet = Bullet.new @window, "media/bullet.bmp", @space, @max_x_coord, @max_y_coord, @scale

    bullet_angle = -@shape.body.a + Math::PI / 2
    bullet_speed = 100 * @scale

    bullet.shape.body.v = (CP::Vec2.new(Math.sin(bullet_angle) * bullet_speed, Math.cos(bullet_angle) * bullet_speed))
    bullet.shape.body.p = @shape.body.p + bullet.shape.body.v
    bullet.shape.body.a = @shape.body.a

    bullet
  end
end