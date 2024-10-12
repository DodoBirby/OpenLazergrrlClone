extends Node

@onready var button_container: HBoxContainer = %ButtonContainer
@onready var server_player: Player = %ServerPlayer
@onready var client_player: Player = %ClientPlayer
@onready var sync_lost_label: Label = %SyncLostLabel
@onready var camera: Camera2D = %Camera
@onready var tiles: TileMapLayer = %Tiles
@onready var game_master: GameMaster = %GameMaster
@onready var player_1_bank: Label = %Player1Bank
@onready var player_2_bank: Label = %Player2Bank
@onready var background: CanvasLayer = %Background

const PORT = 64198
const MAX_CLIENTS = 2

const BASE_LOG_PATH = "user://detailed_logs"

var logging_enabled = false

func _ready() -> void:
	background.visible = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	SyncManager.sync_error.connect(_on_sync_error)
	SyncManager.sync_started.connect(_on_sync_started)
	SyncManager.sync_stopped.connect(_on_sync_stopped)
	SyncManager.sync_lost.connect(_on_sync_lost)
	SyncManager.sync_regained.connect(_on_sync_regained)
	server_player.set_multiplayer_authority(1)
	game_master.player1bank = player_1_bank
	game_master.player2bank = player_2_bank
	server_player.tile_pos = Vector2i(2, 5)
	server_player.prev_tile_pos = Vector2i(2, 5)
	client_player.tile_pos = Vector2i(12, 5)
	client_player.prev_tile_pos = Vector2i(12, 5)
	var used_rect = tiles.get_used_rect()
	used_rect.size *= 64
	used_rect.position *= 64
	used_rect = used_rect.grow(128)
	var view_width = get_viewport().size.x
	var view_height = get_viewport().size.y
	var zoom_x = float(view_width) / used_rect.size.x
	var zoom_y = float(view_height) / used_rect.size.y
	camera.zoom = Vector2(min(zoom_x, zoom_y), min(zoom_x, zoom_y))
	camera.position = used_rect.get_center()
func _on_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_sync_started() -> void:
	if logging_enabled:
		if not DirAccess.dir_exists_absolute(BASE_LOG_PATH):
			DirAccess.make_dir_absolute(BASE_LOG_PATH)
		var datetime = Time.get_datetime_string_from_system(true)
		var log_file_name = "%s-peer-%d.log" % [datetime, multiplayer.multiplayer_peer.get_unique_id()]
		SyncManager.start_logging(BASE_LOG_PATH + "/" + log_file_name) 
		
func _on_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()

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
