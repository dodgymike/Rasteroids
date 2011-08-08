#!/usr/bin/ruby -w

require 'gosu'
require 'lib/player'
require 'lib/asteroid'


# Convenience method for converting from radians to a Vec2 vector.
class Numeric
  def radians_to_vec2
    CP::Vec2.new(Math::cos(self), Math::sin(self))
  end
end

# Layering of sprites
module ZOrder
  Background, Stars, Player, UI = *0..3
end


class GameWindow < Gosu::Window
  GAME_WINDOW_WIDTH = 640
  GAME_WINDOW_HEIGHT = 480

  def initialize
    super(GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, false)
    self.caption = "Gosu Tutorial Game"

    @space = CP::Space.new

    @background_image = Gosu::Image.new(self, "media/Space.bmp", true)
    @asteroids = create_asteroids()

    @player = Player.new(Gosu::Image.new(self, "media/Starfighter.bmp", false), @space)
    @player.warp(320, 240)

    @dt = (1.0/60.0)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
  end

  def update
    if button_down? Gosu::KbLeft or button_down? Gosu::GpLeft then
      @player.turn_left
    end
    if button_down? Gosu::KbRight or button_down? Gosu::GpRight then
      @player.turn_right
    end
    if button_down? Gosu::KbUp or button_down? Gosu::GpButton0 then
      @player.accelerate
    end

    @space.step(@dt)
    @player.shape.body.reset_forces
    @asteroids.each do |asteroid|
      asteroid.shape.body.reset_forces
    end
  end

  def draw
    @player.draw
    @asteroids.each do |asteroid|
      asteroid.draw
    end

    @background_image.draw(0, 0, 0);

    @score = 0
    @font.draw("Score: #{@score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end

  def create_asteroids
    asteroids = (1 .. 3).collect do |index|
      asteroid_image_name = "media/asteroid-#{index}.bmp"
      puts "asteroid_image_name (#{asteroid_image_name})"
      asteroid_image = Gosu::Image.new(self, asteroid_image_name, false)
      asteroid = Asteroid.new(asteroid_image, @space)

      asteroid.warp(rand(GAME_WINDOW_WIDTH), rand(GAME_WINDOW_HEIGHT))
      asteroid.random_rotation

      asteroid
    end

    asteroids
  end
end

window = GameWindow.new
window.show
