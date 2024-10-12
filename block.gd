class_name Block
extends Sprite2D

var grid: Grid = preload("res://Grid.tres")

@export var team: int = 0
var game_master: GameMaster

# Saved state
var health: int = 1
var tile_pos: Vector2i
var active: bool = false

func _ready() -> void:
	scale.x = 0.5
	scale.y = 0.5

func interact(_player: Player) -> void:
	pass
	
func place(_player: Player, _pos: Vector2i) -> void:
	pass

func get_connection_directions() -> Array[Vector2i]:
	return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

func adjust_size():
	if active:
		scale.x = 1
		scale.y = 1
		position = grid.grid_to_map(tile_pos)
	else:
		scale.x = 0.5
		scale.y = 0.5
	
func _network_process(_input: Dictionary) -> void:
	adjust_size()

func _network_postprocess(_input: Dictionary) -> void:
	if health <= 0:
		game_master.deregister_block(tile_pos)
		SyncManager.despawn(self)

func damage():
	health -= 1
