require 'gosu'
require 'chipmunk'

class GameEntity
  # The number of steps to process every Gosu update
  # The Player ship can get going so fast as to "move through" a
  # star without triggering a collision; an increased number of
  # Chipmunk step calls per update will effectively avoid this issue
  SUBSTEPS = 6

  attr :shape

  def initialize(image, space)
    @image = image

    if image.nil?
      raise "nil image passed"
    end

    @circle_offset = CP::Vec2.new(0,0)

    @body = CP::Body.new(100, 10)
    @shape = CP::Shape::Circle.new(@body, 32, @circle_offset)
    @body.add_to_space(space)
  end

  def warp(x, y)
    @body.p.x= x
    @body.p.y= y
  end

  def turn_left
    @body.t -= 400.0/SUBSTEPS
  end

  def turn_right
    @body.t += 400.0/SUBSTEPS
  end

  def accelerate
    @shape.body.apply_force((@shape.body.a.radians_to_vec2 * (3000.0/SUBSTEPS)), CP::Vec2.new(0.0, 0.0))
  end

  def random_rotation
    @body.t += (rand(5000000.0) - 2500000)/SUBSTEPS
  end

  def draw
    @image.draw_rot(@body.p.x, @body.p.y, 1, @body.a)
  end
end
