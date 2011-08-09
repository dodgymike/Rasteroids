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

class GameServer
  GAME_WINDOW_WIDTH = 640
  GAME_WINDOW_HEIGHT = 480

  def initialize
    @shape_to_game_entity = {}

    @space = CP::Space.new
    #@space.damping = 0.8

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
  end

  def update
    # check all object positions
    check_object_positions()

    # deal with collisions
    handle_collisions()

    # update the munk-space
    update_munk_space()
  end

  def get_game_state
    {
        :asteroids => @asteroids,
        :players => @players,
        :bullets => @bullets
    }
  end

  def player_shoot player
    add_bullet player.shoot
  end

  def player_accelerate player
    player.accelerate
  end

  def player_turn_left player
    player.turn_left
  end

  def player_turn_right player
    player.turn_right
  end

  def player_boost player
    player.boost
  end

  def player_reverse player
    player.reverse
  end
private
  def add_game_entity_to_shape_lookup game_entity
    @shape_to_game_entity[game_entity.shape] = game_entity
  end

  def get_game_entity_by_shape shape
    @shape_to_game_entity[shape]
  end

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

  def add_bullet bullet
    add_game_entity_to_shape_lookup bullet
    @bullets << bullet
  end

  def add_player
    player = Player.new(self, "media/Starfighter.bmp", 50, 50, @space, GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, 0.5)
    player.warp(CP::Vec2.new(GAME_WINDOW_WIDTH / 2.0, GAME_WINDOW_HEIGHT / 2.0))
    add_game_entity_to_shape_lookup player

    player
  end


  def create_asteroids
    asteroids = (1 .. 3).collect do |index|
      asteroid_image_name = "media/asteroid-#{index}.bmp"
      #puts "asteroid_image_name (#{asteroid_image_name})"
      asteroid = Asteroid.new(self, asteroid_image_name, 100, 100, @space, GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, 1.0)

      asteroid.warp(CP::Vec2.new(rand(GAME_WINDOW_WIDTH), rand(GAME_WINDOW_HEIGHT)))
      asteroid.random_rotation

      add_game_entity_to_shape_lookup asteroid

      asteroid
    end

    asteroids
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
end
