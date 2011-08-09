#!/usr/bin/ruby -w

require 'gosu'
require 'lib/player'
require 'lib/asteroid'
require 'lib/bullet'
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

    @lives = 10
    @score = 0
    @space = CP::Space.new
    #@space.damping = 0.8

    @background_image = Gosu::Image.new(self, "media/Space.bmp", true)

    @asteroids = create_asteroids()
    @asteroids += create_asteroids

    add_player

    @bullets = []

    @asteroids_to_split = []
    @players_with_collisions = []
    @bullets_with_collisions = []

    @space.add_collision_func(Player::COLLISION_NAME, Asteroid::COLLISION_NAME) do |player_shape, asteroid_shape|
      puts "Collision between player (#{player_shape}) and asteroid (#{asteroid_shape})"

      @lives -= 1
      @score -= 10
      @asteroids_to_split << get_game_entity_by_shape(asteroid_shape)
      @players_with_collisions << get_game_entity_by_shape(player_shape)
    end

    @space.add_collision_func(Bullet::COLLISION_NAME, Asteroid::COLLISION_NAME) do |bullet_shape, asteroid_shape|
      puts "Collision between bullet (#{bullet_shape}) and asteroid (#{asteroid_shape})"

      @score += 10
      @asteroids_to_split << get_game_entity_by_shape(asteroid_shape)
      @bullets_with_collisions << get_game_entity_by_shape(bullet_shape)
    end

    @space.add_collision_func(Bullet::COLLISION_NAME, Player::COLLISION_NAME) do |bullet_shape, player_shape|
      puts "Collision between bullet (#{bullet_shape}) and player (#{player_shape})"

      @lives -= 1
      @score -= 10
      @bullets_with_collisions << get_game_entity_by_shape(bullet_shape)
      @players_with_collisions << get_game_entity_by_shape(player_shape)
    end

    @space.add_collision_func(Bullet::COLLISION_NAME, Bullet::COLLISION_NAME) do |bullet_shape_1, bullet_shape_2|
      puts "Collision between bullet (#{bullet_shape_1}) and bullet_shape_2 (#{bullet_shape_2})"

      @bullets_with_collisions << get_game_entity_by_shape(bullet_shape_1)
      @bullets_with_collisions << get_game_entity_by_shape(bullet_shape_2)
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
    @bullets.each do |bullet|
      bullet.draw
    end

    @background_image.draw(0, 0, 0);

    @font.draw("Score: #{@score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
    @font.draw("Lives: #{@lives}", GAME_WINDOW_WIDTH - 150, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
  end

private
  def add_player
    @player = Player.new(self, "media/Starfighter.bmp", @space, GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, 0.5)
    @player.warp(CP::Vec2.new(GAME_WINDOW_WIDTH / 2.0, GAME_WINDOW_HEIGHT / 2.0))
    add_game_entity_to_shape_lookup @player
  end

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

    if button_down? Gosu::KbSpace
      bullet = @player.shoot
      if !bullet.nil?
        @bullets << bullet
        add_game_entity_to_shape_lookup(bullet)
      end
    end
  end

  def check_object_positions
    @player.validate_position
    @asteroids.each do |asteroid|
      asteroid.validate_position
    end
    @bullets.each do |bullet|
      bullet.validate_position
    end
  end

  def update_munk_space
    @space.step(@dt)
    @player.shape.body.reset_forces
    @asteroids.each do |asteroid|
      asteroid.shape.body.reset_forces
    end
    @bullets.each do |bullet|
      bullet.shape.body.reset_forces
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

    while !@bullets_with_collisions.empty?
      bullet = @bullets_with_collisions.pop
      @bullets.delete bullet
      bullet.suicide
    end

    while !@players_with_collisions.empty?
      player = @players_with_collisions.pop
      player.reset
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
