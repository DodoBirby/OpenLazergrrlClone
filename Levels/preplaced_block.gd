@tool
extends Sprite2D

# This should be a direct child of a game master

@export var team: Constants.Teams = Constants.Teams.RED:
	set(value):
		team = value
		if team == Constants.Teams.RED:
			scale.x = 1
		else:
			scale.x = -1
		update_sprite()
@export var type: BlockTypes = BlockTypes.WALL:
	set(value):
		type = value
		update_sprite()

# Sprites
static var red_wall_sprite = preload("res://Assets/Red/Wall_-_Red_64x64.png")
static var blue_wall_sprite = preload("res://Assets/Blue/Wall_-_Blue_64x64.png")
static var red_lazer_sprite = preload("res://Assets/Red/Lazer_-_Red_64x64.png")
static var blue_lazer_sprite = preload("res://Assets/Blue/Lazer_-_Blue_64x64.png")
static var red_gen_sprite = preload("res://Assets/Red/Generator_-_Red_64x64.png")
static var blue_gen_sprite = preload("res://Assets/Blue/Generator_-_Blue_64x64.png")
static var red_base_gen_shop_sprite = preload("res://Assets/Red/Generator_Shop_-_Red_64x64.png")
static var blue_base_gen_shop_sprite = preload("res://Assets/Blue/Generator_Shop_-_Blue_64x64.png")
static var red_base_wall_shop_sprite = preload("res://Assets/Red/Wall_Shop_-_Red_64x64.png")
static var blue_base_wall_shop_sprite = preload("res://Assets/Blue/Wall_Shop_-_Blue_64x64.png")
static var red_base_lazer_shop_sprite = preload("res://Assets/Red/Lazer_Shop_-_Red_64x64.png")
static var blue_base_lazer_shop_sprite = preload("res://Assets/Blue/Lazer_Shop_-_Blue_64x64.png")

# Block Scenes
static var wall_scene = preload("res://Blocks/wall.tscn")
static var gen_scene = preload("res://Blocks/generator.tscn")
static var lazer_scene = preload("res://Blocks/lazer.tscn")
static var base_gen_shop_scene = preload("res://Blocks/BaseShop/base_gen_shop.tscn")
static var base_lazer_shop_scene = preload("res://Blocks/BaseShop/base_lazer_shop.tscn")
static var base_wall_shop_scene = preload("res://Blocks/BaseShop/base_wall_shop.tscn")

var grid: Grid = preload("res://Grid/Grid.tres")

enum BlockTypes {
	WALL,
	LAZER,
	GENERATOR,
	BASE_GEN_SHOP,
	BASE_WALL_SHOP,
	BASE_LAZER_SHOP,
}

var game_master: GameMaster

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	game_master = get_parent()
	SyncManager.sync_started.connect(_on_sync_started)
	SyncManager.scene_spawned.connect(_on_scene_spawned)
	visible = false

func _on_sync_started() -> void:
	SyncManager.spawn("preplaced_block", game_master, get_scene_to_spawn(), {"team": team, "tile_pos": grid.map_to_grid(position)})
	
func _on_scene_spawned(node_name: String, spawned_node: Node, _scene: PackedScene, data: Dictionary) -> void:
	if node_name == "preplaced_block":
		game_master.register_block(spawned_node, data["tile_pos"])
		spawned_node.position = grid.grid_to_map(spawned_node.tile_pos)

func get_scene_to_spawn() -> PackedScene:
	match type:
		BlockTypes.WALL:
			return wall_scene
		BlockTypes.LAZER:
			return lazer_scene
		BlockTypes.GENERATOR:
			return gen_scene
		BlockTypes.BASE_GEN_SHOP:
			return base_gen_shop_scene
		BlockTypes.BASE_WALL_SHOP:
			return base_wall_shop_scene
		BlockTypes.BASE_LAZER_SHOP:
			return base_lazer_shop_scene
	return null

func update_sprite():
	match type:
		BlockTypes.WALL:
			texture = red_wall_sprite if team == Constants.Teams.RED else blue_wall_sprite
		BlockTypes.LAZER:
			texture = red_lazer_sprite if team == Constants.Teams.RED else blue_lazer_sprite
		BlockTypes.GENERATOR:
			texture = red_gen_sprite if team == Constants.Teams.RED else blue_gen_sprite
		BlockTypes.BASE_GEN_SHOP:
			texture = red_base_gen_shop_sprite if team == Constants.Teams.RED else blue_base_gen_shop_sprite
		BlockTypes.BASE_WALL_SHOP:
			texture = red_base_wall_shop_sprite if team == Constants.Teams.RED else blue_base_wall_shop_sprite
		BlockTypes.BASE_LAZER_SHOP:
			texture = red_base_lazer_shop_sprite if team == Constants.Teams.RED else blue_base_lazer_shop_sprite
