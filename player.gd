class_name Player
extends Node2D

@export var team: Constants.Teams = Constants.Teams.RED

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var health_bar: Sprite2D = %HealthBar

# Unsaved state
var grid: Grid = preload("res://Grid/Grid.tres")
var game_master: GameMaster
var desired_pos: Vector2i

# Saved state
# position is saved as well
var facing: Vector2i
var tile_pos: Vector2i
var prev_tile_pos: Vector2i
var held_block: Block
var ticks_to_move: int
var state: STATES = STATES.STATIONARY
var health: int = int(2.5 * Engine.physics_ticks_per_second)

# Constants
# Ticks to move one tile
const MOVE_TICKS = 5

var MAX_HEALTH: int = int(2.5 * Engine.physics_ticks_per_second)

var lazergrrlanim = preload("res://Assets/Characters/LazerGrrlAnims.tres")
var robotronanim = preload("res://Assets/Characters/RoboTronAnim.tres")

# Some calculated values to provide a smooth movement between tiles
const PIXELS_PER_TICK = grid.TILE_SIZE / MOVE_TICKS
const REMAINDER_PIXELS = grid.TILE_SIZE % MOVE_TICKS

enum STATES {
	STATIONARY,
	MOVING,
	DEAD,
}

func _ready() -> void:
	if team == Constants.Teams.RED:
		sprite.sprite_frames = lazergrrlanim
	else:
		sprite.sprite_frames = robotronanim

#region Input Handling
func _predict_remote_input(previous_input: Dictionary, _ticks_since_real_input: int) -> Dictionary:
	if previous_input.is_empty():
		return {}
	var input = previous_input.duplicate()
	input["action"] = false
	input["turn_vector"] = Vector2i.ZERO
	return input

func _get_local_input() -> Dictionary:
	var move_vector: Vector2i = Vector2i.ZERO
	if Input.is_action_pressed("player1_left"):
		move_vector = Vector2i.LEFT
	elif Input.is_action_pressed("player1_right"):
		move_vector = Vector2i.RIGHT
	elif Input.is_action_pressed("player1_down"):
		move_vector = Vector2i.DOWN
	elif Input.is_action_pressed("player1_up"):
		move_vector = Vector2i.UP

	var turn_vector: Vector2i = Vector2i.ZERO
	if Input.is_action_just_pressed("player1_turnup"):
		turn_vector = Vector2i.UP
	elif Input.is_action_just_pressed("player1_turndown"):
		turn_vector = Vector2i.DOWN
	elif Input.is_action_just_pressed("player1_turnleft"):
		turn_vector = Vector2i.LEFT
	elif Input.is_action_just_pressed("player1_turnright"):
		turn_vector = Vector2i.RIGHT

	var action: bool = false
	if turn_vector != Vector2i.ZERO:
		action = true
	return {
		"move_vector": move_vector,
		"turn_vector": turn_vector,
		"action": action
	}
#endregion

#region Network Process
func _network_preprocess(input: Dictionary) -> void:
	if input.is_empty():
		input = {"move_vector": Vector2i.ZERO, "turn_vector": Vector2i.ZERO, "action": false}
	if input.get("turn_vector") != Vector2i.ZERO:
		facing = input.get("turn_vector")
	match state:
		STATES.STATIONARY:
			desired_pos = tile_pos + input.get("move_vector")
			game_master.register_desired_move(self, desired_pos)
			if input.get("action"):
				game_master.register_desired_interact(self, facing)
			if input.get("move_vector") != Vector2i.ZERO:
				facing = input.get("move_vector")
		STATES.MOVING:
			desired_pos = tile_pos
			game_master.register_desired_move(self, desired_pos)
			if input.get("action"):
				game_master.register_desired_interact(self, facing)
		STATES.DEAD:
			game_master.register_desired_move(self, Vector2i.MIN)
			visible = false
			tile_pos = Vector2i.MIN

func _network_postprocess(_input: Dictionary) -> void:
	update_visuals()
	match state:
		STATES.MOVING:
			if ticks_to_move > 0:
				ticks_to_move -= 1
			position = calculate_intermediate_position()
			if ticks_to_move <= 0:
				end_move()
				
func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	position = lerp(old_state["position"], new_state["position"], weight)
#endregion

#region Private functions
func calculate_intermediate_position() -> Vector2:
	var prev_map_pos = grid.grid_to_map(prev_tile_pos)
	var direction = tile_pos - prev_tile_pos
	var ticks_elapsed = MOVE_TICKS - ticks_to_move
	var remainder_pixels = min(REMAINDER_PIXELS, ticks_elapsed)
	return prev_map_pos + direction * ticks_elapsed * PIXELS_PER_TICK + direction * remainder_pixels

func update_visuals() -> void:
	health_bar.material.set_shader_parameter("percent_health", float(health) / MAX_HEALTH)
	sprite.scale.x = 1
	if facing == Vector2i.UP:
		sprite.play("Back")
	elif facing == Vector2i.DOWN:
		sprite.play("Front")
	elif facing == Vector2i.LEFT:
		sprite.play("Side")
		sprite.scale.x = -1
	else:
		sprite.play("Side")
	if held_block:
		held_block.position = grid.grid_to_map(tile_pos + facing)
#endregion

#region Public functions
func damage(amount: int) -> void:
	health -= amount

func end_move() -> void:
	state = STATES.STATIONARY
	prev_tile_pos = tile_pos
	position = grid.grid_to_map(tile_pos)

func start_move(target: Vector2i) -> void:
	if state == STATES.DEAD:
		return
	if target == tile_pos:
		return
	tile_pos = target
	state = STATES.MOVING
	ticks_to_move = MOVE_TICKS
#endregion

#region Save and Load state
func _save_state() -> Dictionary:
	var block_path
	if held_block:
		block_path = held_block.get_path()
	else:
		block_path = null
	return {
		"position": position,
		"tile_pos": tile_pos,
		"prev_tile_pos": prev_tile_pos,
		"ticks_to_move": ticks_to_move,
		"state": state,
		"facing": facing,
		"held_block": block_path,
		"health": health
	}

func _load_state(loaded_state: Dictionary) -> void:
	position = loaded_state["position"]
	tile_pos = loaded_state["tile_pos"]
	prev_tile_pos = loaded_state["prev_tile_pos"]
	ticks_to_move = loaded_state["ticks_to_move"]
	state = loaded_state["state"]
	facing = loaded_state["facing"]
	if loaded_state["held_block"] == null:
		held_block = null
	else:
		held_block = get_node(loaded_state["held_block"])
	health = loaded_state["health"]
	update_visuals()
#endregion
