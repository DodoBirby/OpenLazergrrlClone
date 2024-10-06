class_name Block
extends Sprite2D

var grid: Grid = preload("res://Grid.tres")

@export var team: int = 0
var game_master: GameMaster

# Saved state
var health: int = 0
var tile_pos: Vector2i
var active: bool = false

func _ready() -> void:
	scale.x = 0.25
	scale.y = 0.25

func interact(_player: Player) -> void:
	pass
	
func place(_player: Player, _pos: Vector2i) -> void:
	pass
	
func adjust_size():
	if active:
		scale.x = 0.5
		scale.y = 0.5
		position = grid.grid_to_map(tile_pos)
	else:
		scale.x = 0.25
		scale.y = 0.25
	
func _network_process(input: Dictionary) -> void:
	adjust_size()
	
