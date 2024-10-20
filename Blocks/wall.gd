class_name Wall
extends Block

func _network_spawn(_data: Dictionary) -> void:
	super(_data)
	MAX_HEALTH = 10 * Engine.physics_ticks_per_second
	health = MAX_HEALTH

#region Virtual Block Functions
func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		return
	game_master.move_block_to_hand(player, self)
	
func place(player: Player, pos: Vector2i) -> void:
	game_master.move_hand_to_field(player, pos)
#endregion

#region Save and Load State
func _save_state() -> Dictionary:
	var state: Dictionary = {}
	save_block_state(state)
	return state
	
func _load_state(state: Dictionary) -> void:
	load_block_state(state)
	return
#endregion
