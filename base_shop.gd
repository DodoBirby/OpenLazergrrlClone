class_name BaseShop
extends Block

@export var product: PackedScene

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
