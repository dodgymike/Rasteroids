#!/usr/bin/ruby -w

require 'gosu'
require 'lib/player'
require 'lib/asteroid'
require 'pp'

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

    @shape_to_game_entity = {}

    @score = 0
    @space = CP::Space.new
    #@space.damping = 0.8

    @background_image = Gosu::Image.new(self, "media/Space.bmp", true)

    @asteroids = create_asteroids()
    @asteroids += create_asteroids

    @player = Player.new(self, "media/Starfighter.bmp", @space, GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, 0.5)
    @player.warp(CP::Vec2.new(320, 240))
    add_game_entity_to_shape_lookup @player

    # Here we define what is supposed to happen when a Player (ship) collides with a Star
    # I create a @remove_shapes array because we cannot remove either Shapes or Bodies
    # from Space within a collision closure, rather, we have to wait till the closure
    # is through executing, then we can remove the Shapes and Bodies
    # In this case, the Shapes and the Bodies they own are removed in the Gosu::Window.update phase
    # by iterating over the @remove_shapes array
    # Also note that both Shapes involved in the collision are passed into the closure
    # in the same order that their collision_types are defined in the add_collision_func call
    @asteroids_to_split = []
    @players_with_collisions = []

    @space.add_collision_func(@player.collision_name, @asteroids[0].collision_name) do |player_shape, asteroid_shape|
      puts "Collision between player (#{player_shape}) and asteroid (#{asteroid_shape})"

      @score += 10
      @asteroids_to_split << get_game_entity_by_shape(asteroid_shape)
      @players_with_collisions << get_game_entity_by_shape(player_shape)
    end

    @dt = (1.0/60.0)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)

    #pp @shape_to_game_entity
  end

  def update
    # Check keyboard
    handle_key_events()

    # check all object positions
    check_object_positions()

    # deal with collisions
    handle_collisions()

    # update the munk-space
    update_munk_space()
  end

  def draw
    @player.draw
    @asteroids.each do |asteroid|
      asteroid.draw
    end

    @background_image.draw(0, 0, 0);

    @font.draw("Score: #{@score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
  end

private
  def add_game_entity_to_shape_lookup game_entity
    #puts "add_game_entity_to_shape_lookup:"
    #pp game_entity
    @shape_to_game_entity[game_entity.shape] = game_entity
  end

  def get_game_entity_by_shape shape
    #puts "get_game_entity_by_shape:"
    #pp shape
    @shape_to_game_entity[shape]
  end

  def handle_key_events
    if button_down? Gosu::KbLeft
      @player.turn_left
    end
    if button_down? Gosu::KbRight
      @player.turn_right
    end

    if button_down? Gosu::KbUp
      if ((button_down? Gosu::KbRightShift) || (button_down? Gosu::KbLeftShift))
        @player.boost
      else
        @player.accelerate
      end
    elsif button_down? Gosu::KbDown
      @player.reverse
    end
  end

  def check_object_positions
    @player.validate_position
    @asteroids.each do |asteroid|
      asteroid.validate_position
    end
  end

  def update_munk_space
    @space.step(@dt)
    @player.shape.body.reset_forces
    @asteroids.each do |asteroid|
      asteroid.shape.body.reset_forces
    end
  end

  def handle_collisions
    while !@asteroids_to_split.empty?
      # remove the original asteroid
      asteroid_to_split = @asteroids_to_split.pop
      @asteroids.delete asteroid_to_split
      asteroid_to_split.suicide

        # make clones, which has the magic side-effect of adding
        # the new asteroids to the space
      #add_game_entity_to_shape_lookup asteroid_to_split.mini_me
      asteroid_1 = asteroid_to_split.mini_me
      if !asteroid_1.nil?
        add_game_entity_to_shape_lookup asteroid_1
        @asteroids << asteroid_1
      end
    end
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end

  def create_asteroids
    asteroids = (1 .. 3).collect do |index|
      asteroid_image_name = "media/asteroid-#{index}.bmp"
      #puts "asteroid_image_name (#{asteroid_image_name})"
      asteroid = Asteroid.new(self, asteroid_image_name, @space, GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, 1.0)

      asteroid.warp(CP::Vec2.new(rand(GAME_WINDOW_WIDTH), rand(GAME_WINDOW_HEIGHT)))
      asteroid.random_rotation

      add_game_entity_to_shape_lookup asteroid

      asteroid
    end

    asteroids
  end

end

window = GameWindow.new
window.show
