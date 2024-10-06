class_name Lazer
extends Block

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
