#!/usr/bin/ruby -w

require 'drb'
require 'gosu'
require 'lib/player'
require 'lib/asteroid'
require 'lib/bullet'
require 'lib/game_server'
require 'pp'

# Layering of sprites
module ZOrder
  Background, Stars, Player, UI = *0..3
end


class GameWindow < Gosu::Window
  GAME_WINDOW_WIDTH = 640
  GAME_WINDOW_HEIGHT = 480

  def initialize game_server
    super(GAME_WINDOW_WIDTH, GAME_WINDOW_HEIGHT, false)
    self.caption = "Capetown.rb Asteroids"

    @background_image = Gosu::Image.new(self, "media/Space.bmp", true)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)

    # a 'keypress' must last at least 200ms
    @min_keypress_time = 0.200
    @last_keypress_time = Time.now.to_f

    @game_server = game_server
    @player_id = @game_server.join_game

    @image_cache = {}

    @game_state = nil
  end

  def update
    # Check keyboard
    handle_key_events()

    @game_server.update
    @game_state = @game_server.get_game_state
  end

  def draw
    @game_state[:players].each do |player|
      draw_game_entity(player)
    end
    @game_state[:asteroids].each do |asteroid|
      draw_game_entity(asteroid)
    end
    @game_state[:bullets].each do |bullet|
      draw_game_entity(bullet)
    end

    @game_state[:players].each_with_index do |player, index|
      info_y_position = (index * 12) + 10
      @font.draw("Score: #{player.score}", 10, info_y_position, ZOrder::UI, 1.0, 1.0, 0xffffff00)
      @font.draw("Lives: #{player.lives}", GAME_WINDOW_WIDTH - 150, info_y_position, ZOrder::UI, 1.0, 1.0, 0xffffff00)
    end

    @background_image.draw(0, 0, 0);
  end

private
  def draw_game_entity game_entity
    image_from_cache(game_entity).draw_rot(game_entity.x, game_entity.y, ZOrder::Player, game_entity.a, 0.5, 0.5, game_entity.scale, game_entity.scale)
  end

  def image_from_cache game_entity
    if @image_cache[game_entity.entity_id].nil?
      @image_cache[game_entity.entity_id] = Gosu::Image.new self, game_entity.entity_id, false
    end

    @image_cache[game_entity.entity_id]
  end

  def handle_key_events
    if @game_state.nil?
      return
    end

    local_player = @game_state[:players][0]

    if button_down? Gosu::KbLeft
      @game_server.player_turn_left @player_id
    end
    if button_down? Gosu::KbRight
      @game_server.player_turn_right @player_id
    end

    if button_down? Gosu::KbUp
      if ((button_down? Gosu::KbRightShift) || (button_down? Gosu::KbLeftShift))
        @game_server.player_boost @player_id
      else
        @game_server.player_accelerate @player_id
      end
    elsif button_down? Gosu::KbDown
      @game_server.player_reverse @player_id
    end

    # TIMED KEY PRESSES
    # the following keypresses will only be actioned if it has been
    # at least @min_keypress_time since the previous keypress
    current_time = Time.now.to_f
    last_keypress_delta = current_time - @last_keypress_time

    if last_keypress_delta >= @min_keypress_time
      @last_keypress_time = current_time

      if button_down? Gosu::KbSpace
        @game_server.player_shoot @player_id
      end
    end
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end
end

DRb.start_service
game_server = DRbObject.new nil, ARGV.shift

window = GameWindow.new game_server
window.show
