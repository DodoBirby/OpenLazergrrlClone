class_name Generator
extends Block

var MAX_CHARGE: int = int(2.5 * Engine.physics_ticks_per_second)

var charge: int = 0
var target = null

func _ready() -> void:
	scale.x = 0.5
	scale.y = 0.5
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
	charge += 1
	if charge >= MAX_CHARGE and target:
		target.power_up()
		charge = 0

func adjust_size():
	if active:
		scale.x = 1
		scale.y = 1
		position = grid.grid_to_map(tile_pos)
	else:
		scale.x = 0.5
		scale.y = 0.5


func _save_state() -> Dictionary:
	var target_path
	if target:
		target_path = target.get_path()
	else:
		target_path = null
	return {
		"target": target_path,
		"active": active,
		"health": health,
		"charge": charge,
		"tile_pos": tile_pos
	}

func _load_state(state: Dictionary) -> void:
	active = state["active"]
	health = state["health"]
	charge = state["charge"]
	tile_pos = state["tile_pos"]
	if state["target"] == null:
		target = null
	else:
		target = get_node(state["target"])
	adjust_size()
