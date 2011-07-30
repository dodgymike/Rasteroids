#!/usr/bin/ruby -w

require 'gosu'
require 'lib/player'
require 'lib/asteroid'

class GameWindow < Gosu::Window
  GAME_WINDOW_WIDTH = 640
  GAME_WINDOW_HEIGHT = 480

  def initialize
    super(GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, false)
    self.caption = "Gosu Tutorial Game"

    @background_image = Gosu::Image.new(self, "media/Space.bmp", true)
    @asteroids = create_asteroids()

    @player = Player.new(self, Gosu::Image.new(self, "media/Starfighter.bmp", false))
    @player.warp(320, 240)
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
    @player.move
  end

  def draw
    @player.draw
    @asteroids.each do |asteroid|
      asteroid.draw
    end

    @background_image.draw(0, 0, 0);

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
      asteroid = Asteroid.new(self, asteroid_image)
      asteroid.warp(rand(GAME_WINDOW_WIDTH/2), rand(GAME_WINDOW_HEIGHT/2))
      asteroid
    end

    asteroids
  end
end

window = GameWindow.new
window.show
