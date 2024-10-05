class_name Generator
extends Block

var MAX_CHARGE: int = int(2.5 * Engine.physics_ticks_per_second)

var charge: int = 0

func _ready() -> void:
	health = 5 * Engine.physics_ticks_per_second

func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		return
	game_master.move_block_to_hand(player, self)
	
func place(player: Player, pos: Vector2i) -> void:
	game_master.move_hand_to_field(player, pos)

func _save_sate() -> Dictionary:
	return {
		"health": health,
		"charge": charge,
		"tile_pos": tile_pos
	}

func _load_state(state: Dictionary) -> void:
	health = state["health"]
	charge = state["charge"]
	tile_pos = state["tile_pos"]
