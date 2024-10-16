class_name BaseShop
extends Block

@export var product: PackedScene

func _network_spawn(_data: Dictionary) -> void:
	super(_data)
	SyncManager.scene_spawned.connect(_on_scene_spawned)

#region Virtual Block Functions
func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		SyncManager.despawn(player.held_block)
		player.held_block = null
	else:
		player.held_block = SyncManager.spawn("shop_product", game_master, product, { "team": team })

func damage() -> void:
	game_master.deal_base_damage(team)
#endregion
	
func _on_scene_spawned(node_name: String, spawned_node: Node, _scene: PackedScene, _data: Dictionary):
	if node_name == "shop_product":
		spawned_node.game_master = game_master
