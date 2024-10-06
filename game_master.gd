class_name GameMaster
extends Node

var grid: Grid = preload("res://Grid.tres")

var players: Array[Player]
var lazers: Array[Lazer]
var generators: Array[Generator]
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
	
	for generator in generators:
		generator.target = null

	for lazer in lazers:
		var found_gens = find_closest_generators(lazer)
		if found_gens.size() == 0:
			continue
		# Oldest gen placed breaks ties if there are two equally close generators
		for generator in generators:
			if found_gens.has(generator):
				generator.target = lazer
				break
	for lazer in lazers:
		if lazer.charge > 0:
			lazer_shoot(lazer)

func lazer_shoot(lazer: Lazer):
	var team = lazer.team
	var facing = lazer.facing
	var starting_pos = lazer.tile_pos + facing
	var current_pos = starting_pos
	while not block_map.has(current_pos) and current_pos.x <= 15:
		current_pos += facing
	if block_map.has(current_pos) and block_map[current_pos].team != team:
		block_map[current_pos].damage()


func find_closest_generators(lazer: Lazer) -> Array[Generator]:
	var queue = [lazer.tile_pos]
	var seen: Dictionary = { lazer.tile_pos: true }
	var team = lazer.team
	var found_generator = false
	var result: Array[Generator] = []
	while queue.size() > 0:
		var pos = queue.pop_front()
		if block_map[pos] is Generator and block_map[pos].target == null:
			found_generator = true
			result.append(block_map[pos])
		if found_generator:
			continue
		var neighbours = find_connecting_blocks(pos, team)
		for neighbour in neighbours:
			if not seen.has(neighbour.tile_pos):
				seen[neighbour.tile_pos] = true
				queue.append(neighbour.tile_pos)
	return result

func find_connecting_blocks(pos: Vector2i, team: int) -> Array[Block]:
	var pos_connecting_directions = block_map[pos].get_connection_directions()
	var result: Array[Block] = []
	for direction in pos_connecting_directions:
		var new_pos = pos + direction
		if block_map.has(new_pos) and block_map[new_pos].team == team:
			var reverse_direction = -direction
			if block_map[new_pos].get_connection_directions().has(reverse_direction):
				result.append(block_map[new_pos])
	return result

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
	if block is Lazer:
		lazers.append(block)
	elif block is Generator:
		generators.append(block)

func deregister_block(pos: Vector2i) -> void:
	if block_map[pos] is Lazer:
		lazers.erase(block_map[pos])
	elif block_map[pos] is Generator:
		generators.erase(block_map[pos])
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
	var save_state: Dictionary = {"blocks": {}, "lazers": [], "generators": [] }
	for pos in block_map:
		save_state["blocks"][pos] = block_map[pos].get_path()
	for lazer in lazers:
		save_state["lazers"].append(lazer.get_path())
	for gen in generators:
		save_state["generators"].append(gen.get_path())
	return save_state
	
func _load_state(state: Dictionary) -> void:
	block_map.clear()
	lazers.clear()
	generators.clear()
	for pos in state["blocks"]:
		block_map[pos] = get_node(state["blocks"][pos])
	for lazer in state["lazers"]:
		lazers.append(get_node(lazer))
	for gen in state["generators"]:
		generators.append(get_node(gen))
	
func _on_scene_spawned(node_name: String, spawned_node: Node, _scene: PackedScene, data: Dictionary):
	if node_name == "shop_product":
		spawned_node.game_master = self
		spawned_node.team = data["team"]
