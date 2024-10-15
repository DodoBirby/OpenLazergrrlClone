class_name BaseShop
extends Block

@onready var sprite: Sprite2D = %Sprite
@export var product: PackedScene
@export var texture: Texture2D

func _ready() -> void:
	sprite.texture = texture
	SyncManager.scene_spawned.connect(_on_scene_spawned)

func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		SyncManager.despawn(player.held_block)
		player.held_block = null
	else:
		player.held_block = SyncManager.spawn("shop_product", get_parent(), product, { "team": team })

func damage() -> void:
	game_master.deal_base_damage(team)
	
func _on_scene_spawned(node_name: String, spawned_node: Node, _scene: PackedScene, data: Dictionary):
	if node_name == "shop_product":
		spawned_node.game_master = game_master
		spawned_node.team = data["team"]
		spawned_node.set_team_texture()
