class_name Block
extends Sprite2D

var grid: Grid = preload("res://Grid.tres")
var health: int = 0
@export var team: int = 0
var game_master: GameMaster
var tile_pos: Vector2i
var active: bool = false

func interact(_player: Player) -> void:
	pass
	
func place(_player: Player, _pos: Vector2i) -> void:
	pass

func _process(delta: float) -> void:
	if active:
		visible = true
		position = grid.grid_to_map(tile_pos)
	else:
		visible = false
