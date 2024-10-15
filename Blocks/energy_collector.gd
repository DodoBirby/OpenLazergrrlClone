class_name EnergyCollector
extends Block

func power_up() -> void:
	game_master.add_to_bank(team, 1)
