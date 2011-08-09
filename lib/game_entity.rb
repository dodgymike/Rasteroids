require 'gosu'
require 'chipmunk'

class GameEntity
  # The number of steps to process every Gosu update
  # The Player ship can get going so fast as to "move through" a
  # star without triggering a collision; an increased number of
  # Chipmunk step calls per update will effectively avoid this issue
  SUBSTEPS = 6

  attr :shape

  def initialize(window, image_name, space, max_x_coord, max_y_coord, scale)
    @scale = scale
    @window = window
    @space = space

    if !image_name.nil?
      @image_name = image_name
      @image = Gosu::Image.new(@window, image_name, false)

      if @image.nil?
        raise "nil image passed"
      end
    end

    @body = CP::Body.new(50 * (scale ** 2), 50 * (scale ** 2))
    create_collision_shape()

    @body.add_to_space(space)
    @shape.add_to_space(space)


    @max_x_coord = max_x_coord
    @max_y_coord = max_y_coord

    reset
  end

  def reset
    @shape.body.p = CP::Vec2.new(@max_x_coord / 2.0, @max_y_coord / 2.0) # position
    @shape.body.v = CP::Vec2.new(0.0, 0.0) # velocity

    # Keep in mind that down the screen is positive y, which means that PI/2 radians,
    # which you might consider the top in the traditional Trig unit circle sense is actually
    # the bottom; thus 3PI/2 is the top
    @shape.body.a = (3*Math::PI/2.0) # angle in radians; faces towards top of screen
  end

  def suicide
    @body.remove_from_space(@space)
    @shape.remove_from_space(@space)
  end

  def mini_me
    mini_me_scale = @scale / 2.0

    # sanity check
    if mini_me_scale <= 0.1
      return nil
    end

    new_entity = self.class.new @window, @image_name, @space, @max_x_coord, @max_y_coord, mini_me_scale
    new_entity.shape.body.p = @body.p
    new_entity.shape.body.t = @body.t
    new_entity.shape.body.v = @body.v

    new_entity
  end

  def create_collision_shape
    @circle_offset = CP::Vec2.new(0,0)

    shape_radius = (((@image.width > @image.height) ? @image.width : @image.height) / 2) * @scale
    @shape = CP::Shape::Circle.new(@body, shape_radius, @circle_offset)

    # The collision_type of a shape allows us to set up special collision behavior
    # based on these types. The actual value for the collision_type is arbitrary
    # and, as long as it is consistent, will work for us; of course, it helps to have it make sense
    @shape.collision_type = collision_name
  end

  # Directly set the position of our Player
  def warp(vect)
    @shape.body.p = vect
  end

  # Apply negative Torque; Chipmunk will do the rest
  # SUBSTEPS is used as a divisor to keep turning rate constant
  # even if the number of steps per update are adjusted
  def turn_left
    @shape.body.t -= 400.0/SUBSTEPS
  end

  # Apply positive Torque; Chipmunk will do the rest
  # SUBSTEPS is used as a divisor to keep turning rate constant
  # even if the number of steps per update are adjusted
  def turn_right
    @shape.body.t += 400.0/SUBSTEPS
  end

  # Apply forward force; Chipmunk will do the rest
  # SUBSTEPS is used as a divisor to keep acceleration rate constant
  # even if the number of steps per update are adjusted
  # Here we must convert the angle (facing) of the body into
  # forward momentum by creating a vector in the direction of the facing
  # and with a magnitude representing the force we want to apply
  def accelerate
    @shape.body.apply_force((@shape.body.a.radians_to_vec2 * (10000.0/SUBSTEPS)), CP::Vec2.new(0.0, 0.0))
  end

  # Apply even more forward force
  # See accelerate for more details
  def boost
    @shape.body.apply_force((@shape.body.a.radians_to_vec2 * (10000.0)), CP::Vec2.new(0.0, 0.0))
  end

  # Apply reverse force
  # See accelerate for more details
  def reverse
    @shape.body.apply_force(-(@shape.body.a.radians_to_vec2 * (10000.0/SUBSTEPS)), CP::Vec2.new(0.0, 0.0))
  end

  # Wrap to the other side of the screen when we fly off the edge
  def validate_position
    l_position = CP::Vec2.new(@shape.body.p.x % @max_x_coord, @shape.body.p.y % @max_y_coord)
    @shape.body.p = l_position
  end

  def draw
    @image.draw_rot(@shape.body.p.x, @shape.body.p.y, ZOrder::Player, @shape.body.a.radians_to_gosu, 0.5, 0.5, @scale, @scale)
  end

  def random_rotation
    @body.t += (rand(50000.0) - 25000)/SUBSTEPS
  end
end




