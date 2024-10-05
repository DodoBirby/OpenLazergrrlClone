extends Node

@onready var button_container: HBoxContainer = %ButtonContainer
@onready var server_player: Player = %ServerPlayer
@onready var client_player: Player = %ClientPlayer

const PORT = 64198
const MAX_CLIENTS = 2

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	server_player.set_multiplayer_authority(1)

func _on_server_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	button_container.hide()

func _on_client_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", PORT)
	multiplayer.multiplayer_peer = peer
	button_container.hide()

func _on_connected_to_server() -> void:
	client_player.set_multiplayer_authority(multiplayer.get_unique_id())

func _on_peer_connected(id: int) -> void:
	SyncManager.add_peer(id)
	if multiplayer.is_server():
		client_player.set_multiplayer_authority(id)
		await get_tree().create_timer(2).timeout
		SyncManager.start()
	
