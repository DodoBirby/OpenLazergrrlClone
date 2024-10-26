class_name Block
extends Node2D

@export var red_team_texture: Texture2D
@export var blue_team_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite

# Unsaved state
var grid: Grid = preload("res://Grid/Grid.tres")
var game_master: GameMaster
var MAX_HEALTH: int = 1

# Initialized state
@export var team: Constants.Teams = Constants.Teams.RED
var sell_price: int = 0

# Saved state
var health: int = 1
var tile_pos: Vector2i
var active: bool = false

signal destroyed

# data.keys = ["team"]
func _network_spawn(data: Dictionary) -> void:
	add_to_group("network_sync")
	team = data["team"]
	sprite.scale.x = 0.5
	sprite.scale.y = 0.5
	sprite.texture = red_team_texture if team == Constants.Teams.RED else blue_team_texture

#region Virtual Block Methods
# Called when the player uses action while targeting this block on the field
func interact(_player: Player) -> void:
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
	return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

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
	update_visuals()

func _interpolate_state(_old_state: Dictionary, new_state: Dictionary, _weight: float) -> void:
	tile_pos = new_state["tile_pos"]
	active = new_state["active"]
	update_visuals()

func _network_despawn() -> void:
	if active:
		deregister()

#region Save and Load State
# Call in child classes to save the block specific state
func save_block_state(state: Dictionary) -> void:
	state["health"] = health
	state["tile_pos"] = tile_pos
	state["active"] = active

# Call in child classes to load the block specific state
func load_block_state(state: Dictionary) -> void:
	health = state["health"]
	tile_pos = state["tile_pos"]
	active = state["active"]
	update_visuals()
#endregion
