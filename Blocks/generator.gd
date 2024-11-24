class_name Generator
extends Block

# Saved State
var _charge: int = 0
var charge: int = 0:
	set(value):
		SyncManager.set_synced(self, "_charge", value)
	get:
		return _charge

var _target = null
var target = null:
	set(value):
		SyncManager.set_synced(self, "_target", value)
	get:
		return _target

# Psuedo Constant
var MAX_CHARGE: int = int(2.5 * Engine.physics_ticks_per_second)

func _network_spawn(_data: Dictionary) -> void:
	super(_data)
	MAX_HEALTH = 5 * Engine.physics_ticks_per_second
	health = MAX_HEALTH
	sell_price = 5
	EventBus.lazer_deregistered.connect(_on_lazer_deregistered)

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
	if not game_master.is_reactor_spot(tile_pos):
		return
	charge += 1
	# Block destruction has already happened so we know target is valid and alive
	if charge >= MAX_CHARGE and target and target.active:
		target.power_up()
		charge = 0

func _on_lazer_deregistered(lazer: Lazer):
	if target == lazer:
		target = null
