extends Node

@onready var button_container: HBoxContainer = %ButtonContainer
@onready var sync_lost_label: Label = %SyncLostLabel
@onready var background: CanvasLayer = %Background
@onready var arena: Level = %Arena

const PORT = 64198
const MAX_CLIENTS = 2

const BASE_LOG_PATH = "user://detailed_logs"


func _ready() -> void:
	background.visible = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	SyncManager.sync_error.connect(_on_sync_error)
	SyncManager.sync_stopped.connect(_on_sync_stopped)
	SyncManager.sync_lost.connect(_on_sync_lost)
	SyncManager.sync_regained.connect(_on_sync_regained)
	
func _on_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_sync_regained() -> void:
	sync_lost_label.visible = false
		
func _on_sync_stopped() -> void:
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()

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
	arena.register_client_peer_id(multiplayer.get_unique_id())

func _on_peer_connected(id: int) -> void:
	SyncManager.add_peer(id)
	if multiplayer.is_server():
		arena.register_client_peer_id(id)
		await get_tree().create_timer(2).timeout
		SyncManager.start()

func _on_sync_error(msg: String):
	print(msg)
	multiplayer.multiplayer_peer = null


func _on_stop_button_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()
