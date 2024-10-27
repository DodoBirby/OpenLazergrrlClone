class_name Level
extends Node
@onready var floor_tiles: TileMapLayer = %FloorTiles
@onready var camera: Camera2D = %Camera
@onready var game_master: GameMaster = %GameMaster
@onready var foreground: TileMapLayer = %Foreground
@onready var server_player: Player = %ServerPlayer
@onready var client_player: Player = %ClientPlayer
@onready var end_game_label: Label = %EndGameLabel
@onready var background: CanvasLayer = %Background

func _ready() -> void:
	background.visible = true
	server_player.set_multiplayer_authority(1)
	fit_camera_to_map()
	game_master.player1bank = %Player1Bank
	game_master.player2bank = %Player2Bank
	game_master.start_timer = %StartTimer
	game_master.end_game_label = end_game_label
	if SyncManager.network_adaptor.is_network_host():
		for player in Lobby.players:
			if player != 1:
				client_player.set_multiplayer_authority(player)
	else:
		client_player.set_multiplayer_authority(multiplayer.get_unique_id())
		camera.zoom.x *= -1
		game_master.left_player = 2
		game_master.right_player = 1
		client_player.mirror_scaling = Vector2i(-1, 1)
	Lobby.scene_loaded.rpc_id(1)

func fit_camera_to_map() -> void:
	var used_rect = floor_tiles.get_used_rect()
	used_rect.position *= 64
	used_rect.size *= 64
	used_rect = used_rect.grow(80)
	var view_size = get_viewport().size
	var zoom_x = float(view_size.x) / used_rect.size.x
	var zoom_y = float(view_size.y) / used_rect.size.y
	camera.position = used_rect.get_center()
	var zoom = min(zoom_x, zoom_y)
	camera.zoom = Vector2(zoom, zoom)

func reactor_at_tile_pos(pos: Vector2i) -> bool:
	return foreground.get_cell_source_id(pos) != -1

func tile_has_floor(pos: Vector2i) -> bool:
	return floor_tiles.get_cell_source_id(pos) != -1

func register_client_peer_id(peer_id: int):
	client_player.set_multiplayer_authority(peer_id)
