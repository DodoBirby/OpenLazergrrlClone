class_name GameMaster
extends Node

var grid: Grid = preload("res://Grid.tres")

var players: Array[Player]
var allowed_move: Dictionary
var desired_moves: Dictionary
var desired_interacts: Dictionary
var block_map: Dictionary

func _ready() -> void:
	SyncManager.scene_spawned.connect(_on_scene_spawned)
	for child in get_children():
		if child is Player:
			child.game_master = self
			players.append(child)
		if child is Shop:
			child.game_master = self
			register_block(child, grid.map_to_grid(child.position))
			child.position = grid.grid_to_map(child.tile_pos)

func _network_process(_input: Dictionary) -> void:
	for player in players:
		if allowed_move[player] and desired_moves[player.desired_pos] == 1:
			player.start_move(player.desired_pos)
	desired_moves.clear()
	for player in desired_interacts:
		var pos = desired_interacts[player]
		if block_map.has(pos):
			block_map[pos].interact(player)
		elif player.held_block and can_place(pos):
			player.held_block.place(player, pos)
	desired_interacts.clear()

func can_place(pos: Vector2i) -> bool:
	for player in players:
		if player.tile_pos == pos:
			return false
	return true

func register_block(block: Block, pos: Vector2i) -> void:
	block_map[pos] = block
	block.game_master = self
	block.tile_pos = pos
	block.active = true

func deregister_block(pos: Vector2i) -> void:
	block_map.erase(pos)

func register_desired_move(player: Player, move: Vector2i) -> void:
	if block_map.has(move):
		allowed_move[player] = false
		return
	desired_moves[move] = desired_moves.get_or_add(move, 0) + 1
	allowed_move[player] = true

func register_desired_interact(player: Player, interact: Vector2i) -> void:
	desired_interacts[player] = interact

func move_block_to_hand(player: Player, block: Block) -> void:
	player.held_block = block
	block.active = false
	deregister_block(block.tile_pos)
	
func move_hand_to_field(player: Player, pos: Vector2i) -> void:
	var block = player.held_block
	register_block(block, pos)
	player.held_block = null

func _save_state() -> Dictionary:
	var save_state: Dictionary = {}
	for pos in block_map:
		save_state[pos] = block_map[pos].get_path()
	return save_state
	
func _load_state(state: Dictionary) -> void:
	block_map.clear()
	for pos in state:
		block_map[pos] = get_node(state[pos])
		
func _on_scene_spawned(node_name: String, spawned_node: Node, _scene: PackedScene, data: Dictionary):
	if node_name == "shop_product":
		spawned_node.game_master = self
		spawned_node.team = data["team"]
