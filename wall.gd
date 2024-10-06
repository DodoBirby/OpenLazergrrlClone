class_name Wall
extends Block

func _ready() -> void:
	super()
	health = 10 * Engine.physics_ticks_per_second

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
		"tile_pos": tile_pos,
	}
	
func _load_state(state: Dictionary) -> void:
	active = state["active"]
	health = state["health"]
	tile_pos = state["tile_pos"]
	adjust_size()
