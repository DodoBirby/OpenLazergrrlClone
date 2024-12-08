class_name Block
extends Node2D

@export var texture: Texture2D

@onready var sprite: Sprite2D = $Sprite

# Unsaved state
var grid: Grid = preload("res://Grid/Grid.tres")
var game_master: GameMaster
var MAX_HEALTH: int = 1
static var all_directions: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
var primary_color: Color
var secondary_color: Color

# Initialized state
@export var team: Constants.Teams = Constants.Teams.RED
var sell_price: int = 0

# Saved state
var _health: int = 1
var health: int = 1:
	set(value):
		SyncManager.set_synced(self, "_health", value)
	get:
		return _health

var _tile_pos: Vector2i
var tile_pos: Vector2i:
	set(value):
		SyncManager.set_synced(self, "_tile_pos", value)
	get:
		return _tile_pos

var _active: bool
var active: bool = false:
	set(value):
		SyncManager.set_synced(self, "_active", value)
	get:
		return _active

signal destroyed

# We need to add network_sync in the ready function so that it's in the group before the spawnmanager checks the value
func _ready() -> void:
	add_to_group("network_sync")

# data.keys = ["team"]
func _network_spawn(data: Dictionary) -> void:
	team = data["team"]
	sprite.scale.x = 0.5
	sprite.scale.y = 0.5
	sprite.texture = texture
	primary_color = PlayerColors.primary_color_map[team]
	secondary_color = PlayerColors.secondary_color_map[team]
	sprite.material.set_shader_parameter("primary_color", primary_color)
	sprite.material.set_shader_parameter("secondary_color", secondary_color)

#region Virtual Block Methods
# Called when the player uses action while targeting this block on the field
func interact(_player: Player, _pos: Vector2i) -> void:
	pass

# Called when player targets an empty location on the field with this block in hand
func place(_player: Player, _pos: Vector2i) -> void:
	pass

# Called when a lazer deals damage to this block
func damage(amount: int):
	health -= amount

# Returns the directions that this block connects to, there must exist a reverse direction
# on the neighbouring block for the connection to be made
func get_connection_directions() -> Array[Vector2i]:
	return all_directions

# Called by the game master to decide if this block should be destroyed
func should_destroy() -> bool:
	return health <= 0

# Called by the game master when this block's should_destroy() function returns true
# Note this function is called in a loop over the block map keys so this shouldn't
# have side effects that affect other blocks
func destroy():
	destroyed.emit()
	game_master.deregister_block(tile_pos)
	SyncManager.despawn(self)
	
# Called by the game master when this block is deregistered (removed from the board)
# This happens when the block is destroyed, or just picked up by the player, or despawned due to rollback while on the board
func deregister():
	pass
#endregion
func update_visuals() -> void:
	sprite.material.set_shader_parameter("percent_health", float(health) / MAX_HEALTH)
	if active:
		sprite.scale.x = 1
		sprite.scale.y = 1
		position = grid.grid_to_map(tile_pos)
	else:
		sprite.scale.x = 0.5
		sprite.scale.y = 0.5
	if team == 2:
		sprite.scale.x = -sprite.scale.x

func _network_postprocess(_input: Dictionary) -> void:
	if not SyncManager.is_in_rollback():
		update_visuals()

func _network_despawn() -> void:
	if active:
		deregister()
