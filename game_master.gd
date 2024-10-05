class_name GameMaster
extends Node

var players: Array[Player]
var desired_moves: Dictionary

func _ready() -> void:
	for child in get_children():
		if child is Player:
			child.game_master = self
			players.append(child)

func _network_process(_input: Dictionary) -> void:
	for player in players:
		if player.registered_move and desired_moves[player.desired_pos] == 1:
			player.start_move(player.desired_pos)
	desired_moves.clear()
	

func register_desired_move(move: Vector2i) -> bool:
	desired_moves[move] = desired_moves.get_or_add(move, 0) + 1
	return true
	# IF TILE NOT MOVEABLE RETURN FALSE

func _save_state() -> Dictionary:
	return {}

func _load_state(_state: Dictionary) -> void:
	pass
