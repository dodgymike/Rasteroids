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
    self.caption = "Capetown.rb Asteroids"

    @shape_to_game_entity = {}

    @lives = 10
    @score = 0
    @space = CP::Space.new
    #@space.damping = 0.8

    @background_image = Gosu::Image.new(self, "media/Space.bmp", true)

    @asteroids = create_asteroids()
    @asteroids += create_asteroids

    @players = []
    @players << add_player

    @bullets = []

    @asteroids_to_split = []
    @players_with_collisions = []
    @bullets_with_collisions = []

    setup_collision_callbacks()

    @dt = (1.0/60.0)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)

    # a 'keypress' must last at least 200ms
    @min_keypress_time = 0.200
    @last_keypress_time = Time.now.to_f
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
    @players.each do |player|
      player.draw
    end
    @asteroids.each do |asteroid|
      asteroid.draw
    end
    @bullets.each do |bullet|
      bullet.draw
    end

    @background_image.draw(0, 0, 0);

    @players.each_with_index do |player, index|
      info_y_position = (index * 12) + 10
      @font.draw("Score: #{player.score}", 10, info_y_position, ZOrder::UI, 1.0, 1.0, 0xffffff00)
      @font.draw("Lives: #{player.lives}", GAME_WINDOW_WIDTH - 150, info_y_position, ZOrder::UI, 1.0, 1.0, 0xffffff00)
    end
  end

private
  def setup_collision_callbacks
    @space.add_collision_func(Player::COLLISION_NAME, Asteroid::COLLISION_NAME) do |player_shape, asteroid_shape|
      puts "Collision between player (#{player_shape}) and asteroid (#{asteroid_shape})"

      player = get_game_entity_by_shape(player_shape)
      player.lives -= 1
      player.score -= 10
      @players_with_collisions << player

      @asteroids_to_split << get_game_entity_by_shape(asteroid_shape)
    end

    @space.add_collision_func(Bullet::COLLISION_NAME, Asteroid::COLLISION_NAME) do |bullet_shape, asteroid_shape|
      puts "Collision between bullet (#{bullet_shape}) and asteroid (#{asteroid_shape})"

      bullet = get_game_entity_by_shape(bullet_shape)
      bullet.player.score += 10
      @bullets_with_collisions << bullet

      @asteroids_to_split << get_game_entity_by_shape(asteroid_shape)
    end

    @space.add_collision_func(Bullet::COLLISION_NAME, Player::COLLISION_NAME) do |bullet_shape, player_shape|
      puts "Collision between bullet (#{bullet_shape}) and player (#{player_shape})"

      # loser!
      player = get_game_entity_by_shape(player_shape)
      player.lives -= 1
      player.score -= 20
      @players_with_collisions << player

      # shooter gets an extra 10 points
      bullet = get_game_entity_by_shape(bullet_shape)
      bullet.player.score += 10
      @bullets_with_collisions << bullet
    end

    @space.add_collision_func(Bullet::COLLISION_NAME, Bullet::COLLISION_NAME) do |bullet_shape_1, bullet_shape_2|
      puts "Collision between bullet (#{bullet_shape_1}) and bullet_shape_2 (#{bullet_shape_2})"

      @bullets_with_collisions << get_game_entity_by_shape(bullet_shape_1)
      @bullets_with_collisions << get_game_entity_by_shape(bullet_shape_2)
    end
  end

  def add_player
    player = Player.new(self, "media/Starfighter.bmp", @space, GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, 0.5)
    player.warp(CP::Vec2.new(GAME_WINDOW_WIDTH / 2.0, GAME_WINDOW_HEIGHT / 2.0))
    add_game_entity_to_shape_lookup player

    player
  end

  def add_game_entity_to_shape_lookup game_entity
    @shape_to_game_entity[game_entity.shape] = game_entity
  end

  def get_game_entity_by_shape shape
    @shape_to_game_entity[shape]
  end

  def handle_key_events
    if button_down? Gosu::KbLeft
      @players[0].turn_left
    end
    if button_down? Gosu::KbRight
      @players[0].turn_right
    end

    if button_down? Gosu::KbUp
      if ((button_down? Gosu::KbRightShift) || (button_down? Gosu::KbLeftShift))
        @players[0].boost
      else
        @players[0].accelerate
      end
    elsif button_down? Gosu::KbDown
      @players[0].reverse
    end

    # TIMED KEY PRESSES
    # the following keypresses will only be actioned if it has been
    # at least @min_keypress_time since the previous keypress
    current_time = Time.now.to_f
    last_keypress_delta = current_time - @last_keypress_time

    if last_keypress_delta >= @min_keypress_time
      @last_keypress_time = current_time

      if button_down? Gosu::KbSpace
        bullet = @players[0].shoot
        if !bullet.nil?
          @bullets << bullet
          add_game_entity_to_shape_lookup(bullet)
        end
      end

      if button_down? Gosu::KbA
        @players << add_player
      end
    end
  end

  def check_object_positions
    @players.each do |player|
      player.validate_position
    end
    @asteroids.each do |asteroid|
      asteroid.validate_position
    end
    @bullets.each do |bullet|
      bullet.validate_position
    end
  end

  def update_munk_space
    @space.step(@dt)
    @players.each do |player|
      player.shape.body.reset_forces
    end
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
