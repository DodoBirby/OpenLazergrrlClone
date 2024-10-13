class_name Lazer
extends Block

var MAX_CHARGE: int = 3 * Engine.physics_ticks_per_second
var charge: int = 0
var facing: Vector2i = Vector2i.RIGHT

var blue_texture = preload("res://Assets/Blue/Lazer_-_Blue_64x64.png")
var red_texture = preload("res://Assets/Red/Lazer_-_Red_64x64.png")

var target_pos: Vector2i = Vector2i.MIN:
	set(value):
		target_pos = value
		queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, scale)
	if target_pos == Vector2i.MIN:
		return
	var start_pos = facing * grid._half_size
	var end_pos = grid.grid_to_map(target_pos) - facing * grid._half_size - Vector2i(position)
	var color = Color(1, 0, 0) if team == 1 else Color(0, 0, 1)
	draw_line(start_pos, end_pos, color, 16)

func _ready() -> void:
	super()
	health = 5 * Engine.physics_ticks_per_second

func set_team_texture():
	# Temporarily putting lazer facing in here because it's convenient
	if team == 1:
		texture = red_texture
		facing = Vector2i.RIGHT
	else:
		texture = blue_texture
		facing = Vector2i.LEFT

func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		return
	target_pos = Vector2i.MIN
	charge = 0
	game_master.move_block_to_hand(player, self)
	
func place(player: Player, pos: Vector2i) -> void:
	game_master.move_hand_to_field(player, pos)

func _network_postprocess(_input: Dictionary) -> void:
	super(_input)
	if charge > 0:
		charge -= 1

func power_up() -> void:
	charge = MAX_CHARGE

func get_connection_directions() -> Array[Vector2i]:
	var all_directions = super()
	all_directions.erase(facing)
	return all_directions

func _save_state() -> Dictionary:
	return {
		"active": active,
		"health": health,
		"charge": charge,
		"facing": facing,
		"tile_pos": tile_pos
	}

func _load_state(state: Dictionary) -> void:
	active = state["active"]
	health = state["health"]
	charge = state["charge"]
	facing = state["facing"]
	tile_pos = state["tile_pos"]
	adjust_size()
