class_name Player
extends Sprite2D

var grid: Grid = preload("res://Grid.tres")

var game_master: GameMaster
var tile_pos: Vector2i
var prev_tile_pos: Vector2i
var ticks_to_move: int
var desired_pos: Vector2i
var registered_move: bool
var facing: Vector2i
var held_block: Block
@export var team: int = 1

# Ticks to move one tile
const MOVE_TICKS = 9

# Some calculated values to provide a smooth movement between tiles
const PIXELS_PER_TICK = grid.TILE_SIZE / MOVE_TICKS
const REMAINDER_PIXELS = grid.TILE_SIZE % MOVE_TICKS

enum STATES {
	STATIONARY,
	MOVING,
}

var state: STATES = STATES.STATIONARY

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
	if turn_vector == Vector2i.ZERO:
		turn_vector = move_vector
	return {
		"move_vector": move_vector,
		"turn_vector": turn_vector,
		"action": action
	}

func _network_preprocess(input: Dictionary) -> void:
	registered_move = false
	if input["turn_vector"] != Vector2i.ZERO:
		facing = input["turn_vector"]
	match state:
		STATES.STATIONARY:
			desired_pos = tile_pos + input["move_vector"]
			game_master.register_desired_move(self, desired_pos)
			if input["action"]:
				game_master.register_desired_interact(self, tile_pos + facing)
		STATES.MOVING:
			desired_pos = tile_pos
			game_master.register_desired_move(self, desired_pos)
			if input["action"]:
				game_master.register_desired_interact(self, tile_pos + facing)

func _network_postprocess(_input: Dictionary) -> void:
	match state:
		STATES.MOVING:
			if ticks_to_move > 0:
				ticks_to_move -= 1
			position = calculate_intermediate_position()
			if ticks_to_move <= 0:
				end_move()

func calculate_intermediate_position() -> Vector2:
	var prev_map_pos = grid.grid_to_map(prev_tile_pos)
	var direction = tile_pos - prev_tile_pos
	var ticks_elapsed = MOVE_TICKS - ticks_to_move
	var remainder_pixels = min(REMAINDER_PIXELS, ticks_elapsed)
	return prev_map_pos + direction * ticks_elapsed * PIXELS_PER_TICK + direction * remainder_pixels

func end_move() -> void:
	state = STATES.STATIONARY
	prev_tile_pos = tile_pos
	position = grid.grid_to_map(tile_pos)

func start_move(target: Vector2i) -> void:
	if target == tile_pos:
		return
	tile_pos = target
	state = STATES.MOVING
	ticks_to_move = MOVE_TICKS

func _save_state() -> Dictionary:
	var block_path
	if held_block:
		block_path = held_block.get_path()
	else:
		block_path = null
	return {
		"tile_pos": tile_pos,
		"prev_tile_pos": prev_tile_pos,
		"ticks_to_move": ticks_to_move,
		"state": state,
		"facing": facing,
		"held_block": block_path
	}

func _load_state(loaded_state: Dictionary) -> void:
	tile_pos = loaded_state["tile_pos"]
	prev_tile_pos = loaded_state["prev_tile_pos"]
	ticks_to_move = loaded_state["ticks_to_move"]
	state = loaded_state["state"]
	facing = loaded_state["facing"]
	if loaded_state["held_block"] == null:
		held_block = null
	else:
		held_block = get_node(loaded_state["held_block"])
