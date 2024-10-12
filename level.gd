class_name Level
extends Node
@onready var floor_tiles: TileMapLayer = %FloorTiles
@onready var camera: Camera2D = %Camera
@onready var game_master: GameMaster = %GameMaster
@onready var foreground: TileMapLayer = %Foreground
@onready var server_player: Player = %ServerPlayer
@onready var client_player: Player = %ClientPlayer

func _ready() -> void:
	server_player.set_multiplayer_authority(1)
	var used_rect = floor_tiles.get_used_rect()
	used_rect.position *= 64
	used_rect.size *= 64
	var view_size = get_viewport().size
	var zoom_x = float(view_size.x) / used_rect.size.x
	var zoom_y = float(view_size.y) / used_rect.size.y
	camera.position = used_rect.get_center()
	var zoom = min(zoom_x, zoom_y)
	camera.zoom = Vector2(zoom, zoom)
	game_master.player1bank = %Player1Bank
	game_master.player2bank = %Player2Bank

func reactor_at_tile_pos(pos: Vector2i) -> bool:
	return foreground.get_cell_source_id(pos) != -1

func tile_has_floor(pos: Vector2i) -> bool:
	return floor_tiles.get_cell_source_id(pos) != -1

func register_client_peer_id(peer_id: int):
	client_player.set_multiplayer_authority(peer_id)
