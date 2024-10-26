class_name BaseShop
extends Block

@export var product: PackedScene
@export var price: int = 0

var BASE_MAX_HEALTH = 30 * Engine.physics_ticks_per_second
var THIRD_OF_BASE_MAX = 10 * Engine.physics_ticks_per_second

func _network_spawn(_data: Dictionary) -> void:
	super(_data)
	SyncManager.scene_spawned.connect(_on_scene_spawned)

#region Virtual Block Functions
func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		var sell_amount: int = player.held_block.sell_price * player.held_block.health / player.held_block.MAX_HEALTH
		game_master.add_to_bank(team, sell_amount)
		SyncManager.despawn(player.held_block)
		player.held_block = null
	else:
		if game_master.get_bank_amount(team) >= price:
			game_master.remove_from_bank(team, price)
			player.held_block = SyncManager.spawn("shop_product", game_master, product, { "team": team })

func damage(amount: int) -> void:
	game_master.deal_base_damage(team, amount)
#endregion

func _network_postprocess(_input: Dictionary) -> void:
	super(_input)
	var distance_from_bottom = 7 - tile_pos.y
	var scaled_base_health = game_master.get_base_health(team) - THIRD_OF_BASE_MAX * distance_from_bottom
	sprite.material.set_shader_parameter("percent_health", float(scaled_base_health) / THIRD_OF_BASE_MAX)
	
func _on_scene_spawned(node_name: String, spawned_node: Node, _scene: PackedScene, _data: Dictionary):
	if node_name == "shop_product":
		spawned_node.game_master = game_master
