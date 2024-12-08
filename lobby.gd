extends Node

var players: Dictionary = {}
var player_name: String = ""
var primary_color: Color = Color.RED
var secondary_color: Color = Color.YELLOW

var players_loaded: Dictionary = {}

signal player_joined
signal player_disconnected
signal failed_to_connect

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_failed_to_connect)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	SyncManager.sync_stopped.connect(_on_sync_stopped)

func host_lobby(port: int):
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 2)
	multiplayer.multiplayer_peer = peer
	players[1] = { "name": player_name, "primary": primary_color, "secondary": secondary_color }

func join_lobby(ip: String, port: int):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer

func get_client_id() -> int:
	for player in players:
		if player != 1:
			return player
	return -1

func set_player_colors():
	PlayerColors.primary_color_map[Constants.Teams.RED] = players[1]["primary"]
	PlayerColors.secondary_color_map[Constants.Teams.RED] = players[1]["secondary"]
	var client_id = get_client_id()
	PlayerColors.primary_color_map[Constants.Teams.BLUE] = players[client_id]["primary"]
	PlayerColors.secondary_color_map[Constants.Teams.BLUE] = players[client_id]["secondary"]

@rpc("authority", "reliable", "call_local")
func start_match():
	players_loaded.clear()
	set_player_colors()
	get_tree().change_scene_to_file("res://Levels/arena.tscn")

@rpc("any_peer", "reliable", "call_local")
func scene_loaded():
	var remote_peer = multiplayer.get_remote_sender_id()
	players_loaded[remote_peer] = true
	if players_loaded.size() >= 2:
		SyncManager.start()

func _on_peer_connected(id: int) -> void:
	_register_player.rpc_id(id, player_name, primary_color, secondary_color)
	SyncManager.add_peer(id)

@rpc("any_peer", "reliable")
func _register_player(peer_name: String, primary: Color, secondary: Color):
	var remote_id = multiplayer.get_remote_sender_id()
	if primary == primary_color and secondary == secondary_color:
		var temp = primary
		primary = secondary
		secondary = temp
	players[remote_id] = { "name": peer_name, "primary": primary, "secondary": secondary }
	player_joined.emit()

func _on_peer_disconnected(id: int):
	players.erase(id)
	player_disconnected.emit()
	SyncManager.remove_peer(id)

func _on_connected_to_server():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = { "name": player_name, "primary": primary_color, "secondary": secondary_color }
	get_tree().change_scene_to_file("res://Menu/lobby_screen.tscn")

func _on_failed_to_connect():
	multiplayer.multiplayer_peer = null
	failed_to_connect.emit()

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	if SyncManager.started:
		SyncManager.stop()
	SyncManager.clear_peers()
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")

func _on_sync_stopped():
	get_tree().change_scene_to_file("res://Menu/lobby_screen.tscn")
