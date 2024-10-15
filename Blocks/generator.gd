class_name Generator
extends Block

# Saved State
var charge: int = 0
var target = null

# Psuedo Constant
var MAX_CHARGE: int = int(2.5 * Engine.physics_ticks_per_second)

func _network_spawn(_data: Dictionary) -> void:
	super(_data)
	health = 5 * Engine.physics_ticks_per_second

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

func _network_postprocess(_input: Dictionary) -> void:
	super(_input)
	if !active:
		return
	charge += 1
	if charge >= MAX_CHARGE and target:
		target.power_up()
		charge = 0

#region Save and Load State
func _save_state() -> Dictionary:
	var state: Dictionary = {}
	save_block_state(state)
	if target:
		#TODO Fix dangling reference when target dies
		state["target"] = target.get_path()
	else:
		state["target"] = null
	state["charge"] = charge
	return state

func _load_state(state: Dictionary) -> void:
	load_block_state(state)
	charge = state["charge"]
	if state["target"] == null:
		target = null
	else:
		target = get_node(state["target"])
#endregion
