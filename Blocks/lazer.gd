class_name Lazer
extends Block

# Saved State
var charge: int = 0
var facing: Vector2i = Vector2i.RIGHT

# Pseudo Constant
var MAX_CHARGE: int = 3 * Engine.physics_ticks_per_second

var target_pos: Vector2i = Vector2i.MIN:
	set(value):
		target_pos = value
		queue_redraw()

func _draw() -> void:
	if target_pos == Vector2i.MIN:
		return
	var start_pos = facing * grid.HALF_SIZE
	var end_pos = grid.grid_to_map(target_pos) - facing * grid.HALF_SIZE - Vector2i(position)
	var color = Color(1, 0, 0) if team == 1 else Color(0, 0, 1)
	draw_line(start_pos, end_pos, color, 16)

func _network_spawn(data: Dictionary) -> void:
	super(data)
	if team == 1:
		facing = Vector2i.RIGHT
	else:
		facing = Vector2i.LEFT
	health = 5 * Engine.physics_ticks_per_second

#region Virtual Block Functions
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

func get_connection_directions() -> Array[Vector2i]:
	var all_directions = super()
	all_directions.erase(facing)
	return all_directions
#endregion

# Generator calls this when it sends power to us
func power_up() -> void:
	charge = MAX_CHARGE

func _network_postprocess(_input: Dictionary) -> void:
	super(_input)
	if charge > 0:
		charge -= 1

#region Save and Load State
func _save_state() -> Dictionary:
	var state: Dictionary = {}
	save_block_state(state)
	state["facing"] = facing
	state["charge"] = charge
	return state

func _load_state(state: Dictionary) -> void:
	load_block_state(state)
	charge = state["charge"]
	facing = state["facing"]
#endregion
