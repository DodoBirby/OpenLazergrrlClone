class_name Lazer
extends Block

var MAX_CHARGE: int = 3 * Engine.physics_ticks_per_second
var charge: int = 0
var facing: Vector2i = Vector2i.RIGHT

func _ready() -> void:
	super()
	health = 5 * Engine.physics_ticks_per_second

func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		return
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
