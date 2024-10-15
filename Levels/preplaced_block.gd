@tool
extends Sprite2D

@export var team: Teams = Teams.RED:
	set(value):
		team = value
		if team == Teams.RED:
			scale.x = 1
		else:
			scale.x = -1
		update_sprite()
@export var type: BlockTypes = BlockTypes.WALL:
	set(value):
		type = value
		update_sprite()

var red_wall_sprite = preload("res://Assets/Red/Wall_-_Red_64x64.png")
var blue_wall_sprite = preload("res://Assets/Blue/Wall_-_Blue_64x64.png")
var red_lazer_sprite = preload("res://Assets/Red/Lazer_-_Red_64x64.png")
var blue_lazer_sprite = preload("res://Assets/Blue/Lazer_-_Blue_64x64.png")
var red_gen_sprite = preload("res://Assets/Red/Generator_-_Red_64x64.png")
var blue_gen_sprite = preload("res://Assets/Blue/Generator_-_Blue_64x64.png")
var red_base_gen_shop_sprite = preload("res://Assets/Red/Generator_Shop_-_Red_64x64.png")
var blue_base_gen_shop_sprite = preload("res://Assets/Blue/Generator_Shop_-_Blue_64x64.png")
var red_base_wall_shop_sprite = preload("res://Assets/Red/Wall_Shop_-_Red_64x64.png")
var blue_base_wall_shop_sprite = preload("res://Assets/Blue/Wall_Shop_-_Blue_64x64.png")
var red_base_lazer_shop_sprite = preload("res://Assets/Red/Lazer_Shop_-_Red_64x64.png")
var blue_base_lazer_shop_sprite = preload("res://Assets/Blue/Lazer_Shop_-_Blue_64x64.png")

enum Teams {
	RED = 1,
	BLUE = 2,
}

enum BlockTypes {
	WALL,
	LAZER,
	GENERATOR,
	BASE_GEN_SHOP,
	BASE_WALL_SHOP,
	BASE_LAZER_SHOP,
}

func update_sprite():
	match type:
		BlockTypes.WALL:
			texture = red_wall_sprite if team == Teams.RED else blue_wall_sprite
		BlockTypes.LAZER:
			texture = red_lazer_sprite if team == Teams.RED else blue_lazer_sprite
		BlockTypes.GENERATOR:
			texture = red_gen_sprite if team == Teams.RED else blue_gen_sprite
		BlockTypes.BASE_GEN_SHOP:
			texture = red_base_gen_shop_sprite if team == Teams.RED else blue_base_gen_shop_sprite
		BlockTypes.BASE_WALL_SHOP:
			texture = red_base_wall_shop_sprite if team == Teams.RED else blue_base_wall_shop_sprite
		BlockTypes.BASE_LAZER_SHOP:
			texture = red_base_lazer_shop_sprite if team == Teams.RED else blue_base_lazer_shop_sprite
