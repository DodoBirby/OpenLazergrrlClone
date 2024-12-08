class_name Shop
extends Block

@export var product: PackedScene

func interact(player: Player, _pos) -> void:
	if player.team != team:
		return
	if player.held_block:
		SyncManager.despawn(player.held_block)
		player.held_block = null
	else:
		player.held_block = SyncManager.spawn("shop_product", get_parent(), product, { "team": team })
