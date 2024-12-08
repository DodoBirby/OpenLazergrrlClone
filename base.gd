class_name Base
extends Block

@onready var sprites: Node2D = %Sprites
@onready var energy_balls: Node2D = %EnergyBalls
@onready var energy_net_bar: Node2D = %EnergyNetBar

enum Shops { GENERATOR, WALL, LAZER, NONE }

# Pseudo-Constants
var gen_shop_offset = Vector2i(1, -1)
var wall_shop_offset = Vector2i(1, 0)
var lazer_shop_offset = Vector2i(1, 1)

var gen_scene = preload("res://Blocks/generator.tscn")
var lazer_scene = preload("res://Blocks/lazer.tscn")
var wall_scene = preload("res://Blocks/wall.tscn")

var shop_offsets = {
	Vector2i(1, -1): Shops.GENERATOR,
	Vector2i(1, 0): Shops.WALL,
	Vector2i(1, 1): Shops.LAZER,
}

var shop_prices = {
	Shops.GENERATOR: 5,
	Shops.WALL: 1,
	Shops.LAZER: 5,
}

var shop_products = {
	Shops.GENERATOR: gen_scene,
	Shops.LAZER: lazer_scene,
	Shops.WALL: wall_scene,
}

var pink_color: Color = Color(1.0, 0.0, 1.0)

func _ready() -> void:
	super()
	_network_spawn({ "team": team })
	MAX_HEALTH = 31 * Engine.physics_ticks_per_second
	health = MAX_HEALTH
	energy_balls.modulate = secondary_color
	if team == Constants.Teams.BLUE:
		sprites.scale.x *= -1
		var new_shop_offsets = {}
		for key in shop_offsets.keys():
			var reversed_key = Vector2i(-key.x, key.y)
			new_shop_offsets[reversed_key] = shop_offsets[key]
		shop_offsets = new_shop_offsets

func interact(player: Player, pos: Vector2i) -> void:
	if player.team != team:
		return
	var shop = get_interacted_shop(pos)
	if shop == Shops.NONE:
		return
	if player.held_block:
		var sell_amount: int = round(float(player.held_block.sell_price * player.held_block.health) / player.held_block.MAX_HEALTH)
		game_master.add_to_bank(team, sell_amount)
		SyncManager.despawn(player.held_block)
		player.held_block = null
	else:
		var price = shop_prices[shop]
		if game_master.get_bank_amount(team) >= price:
			game_master.remove_from_bank(team, price)
			player.held_block = SyncManager.spawn("shop_product", game_master, shop_products[shop], { "team": team })
			player.held_block.game_master = game_master

func _network_postprocess(_input: Dictionary) -> void:
	super(_input)
	var count = 1
	var energy_count = game_master.get_bank_amount(team)
	for child in energy_balls.get_children():
		if count <= energy_count:
			child.visible = true
		else:
			child.visible = false
		count += 1
	
	var net_energy = game_master.get_base_net_energy(team)
	var net_count = abs(net_energy)
	energy_net_bar.modulate = secondary_color if net_energy >= 0 else pink_color
	count = 1
	for child in energy_net_bar.get_children():
		if count <= net_count:
			child.visible = true
		else:
			child.visible = false
		count += 1

func destroy():
	game_master.kill_base(team)

func get_interacted_shop(pos: Vector2i) -> Shops:
	var offset = pos - tile_pos
	return shop_offsets.get(offset, Shops.NONE)
	
