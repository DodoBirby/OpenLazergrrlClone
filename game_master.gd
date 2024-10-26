class_name GameMaster
extends Node

var grid: Grid = preload("res://Grid/Grid.tres")
@export var level: Level

#TODO remove base code from the gamemaster, it's kinda weird for it to be here
#TODO ensure postprocess has no dependent actions

# Saved State
var lazers: Array[Lazer]
var generators: Array[Generator]
var block_map: Dictionary
var base_healthbars: Dictionary = {1: 30 * Engine.physics_ticks_per_second, 2: 30 * Engine.physics_ticks_per_second }
var base_banks: Dictionary = {1: 0, 2: 0}

# Unsaved State
# Temporary Values, only last for a single frame
var allowed_move: Dictionary
var desired_moves: Dictionary
var desired_interacts: Dictionary

# This doesn't have to go into state because it's constant throughout a match
var collectors: Array[EnergyCollector]
var players: Array[Player]

# for test game only
var player1bank: Label = null
var player2bank: Label = null

func _process(_delta: float) -> void:
	player1bank.text = str(base_banks[1])
	player2bank.text = str(base_banks[2])

func _ready() -> void:
	for child in get_children():
		if child is Player:
			child.game_master = self
			players.append(child)
			child.tile_pos = grid.map_to_grid(child.position)
			child.prev_tile_pos = child.tile_pos
			child.position = grid.grid_to_map(child.tile_pos)
		if child is Block:
			child.game_master = self
			register_block(child, grid.map_to_grid(child.position))
			child.position = grid.grid_to_map(child.tile_pos)

# Anything that needs to happen in a strict order should be managed by the game master in this function
# network_processes in other classes should either be network_preprocess or network_postprocess
# so that they explicitly occur before or after this function
# also preprocess and postprocess functions should only contain things that are either purely visual
# or will always happen regardless of any intervening events
func _network_process(_input: Dictionary) -> void:
	for player in players:
		if allowed_move[player] and desired_moves[player.desired_pos] == 1:
			player.start_move(player.desired_pos)
	desired_moves.clear()
	
	for player in desired_interacts:
		var pos = desired_interacts[player] + player.tile_pos
		if block_map.has(pos):
			block_map[pos].interact(player)
		elif player.held_block and can_place(pos):
			player.held_block.place(player, pos)
	desired_interacts.clear()
	
	for generator in generators:
		generator.target = null
	for collector in collectors:
		collector.fake_gen_targets.clear()
	for lazer in lazers:
		request_power(lazer, 1)
	for lazer in lazers:
		lazer.shoot()
	for collector in collectors:
		var found_gens = find_power_sources(collector, 0, false)
		for gen in found_gens:
			gen.target = collector
	# Iterate over the .keys() because entries can get removed here
	for pos in block_map.keys():
		if block_map[pos].should_destroy():
			block_map[pos].destroy()
	
	
#region Private Functions
func has_player(pos: Vector2i) -> bool:
	for player in players:
		if player.tile_pos == pos:
			return true
	return false

func request_power(lazer: Lazer, power_requested: int):
	var found_gens = find_power_sources(lazer, power_requested, true)
	var base: EnergyCollector = null
	if found_gens.back() is EnergyCollector:
		base = found_gens.back()
	if found_gens.size() < power_requested and not base:
		return
	# Oldest gen placed breaks ties if there are two equally close generators
	var power_received = 0
	for generator in generators:
		if found_gens.has(generator):
			generator.target = lazer
			power_received += 1
			if power_received == power_requested:
				break
	if power_received < power_requested and base:
		base.request_power(lazer, power_requested - power_received)

func find_power_sources(block: Block, number_to_find: int, stop_at_closest: bool) -> Array:
	var queue = [block.tile_pos]
	var seen: Dictionary = { block.tile_pos: true }
	var team = block.team
	var base: EnergyCollector = null
	var result = []
	while queue.size() > 0:
		var pos = queue.pop_front()
		if block_map[pos] is Generator and block_map[pos].target == null:
			result.append(block_map[pos])
		elif block_map[pos] is EnergyCollector:
			base = block_map[pos]
		if result.size() >= number_to_find and stop_at_closest:
			continue
		var neighbours = find_connecting_blocks(pos, team)
		for neighbour in neighbours:
			if not seen.has(neighbour.tile_pos):
				seen[neighbour.tile_pos] = true
				queue.append(neighbour.tile_pos)
	if base and result.size() < number_to_find:
		result.append(base)
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
	if not level.tile_has_floor(pos):
		return false
	# We already know the tile is empty of blocks because of where this is called
	# So we just have to check for players
	return not has_player(pos)
#endregion

#region Public Functions
func tile_occupied(pos: Vector2i) -> bool:
	return has_player(pos) or block_map.has(pos)

func lazer_can_pass(pos: Vector2i) -> bool:
	return not tile_occupied(pos) and level.tile_has_floor(pos)

func get_block_at_pos(pos: Vector2i):
	return block_map.get(pos)

func register_block(block: Block, pos: Vector2i) -> void:
	block_map[pos] = block
	block.game_master = self
	block.tile_pos = pos
	block.active = true
	if block is Lazer:
		lazers.append(block)
	elif block is Generator:
		generators.append(block)
	elif block is EnergyCollector:
		collectors.append(block)

func deregister_block(pos: Vector2i) -> void:
	if block_map[pos] is Lazer:
		lazers.erase(block_map[pos])
	elif block_map[pos] is Generator:
		generators.erase(block_map[pos])
	block_map.erase(pos)

func register_desired_move(player: Player, move: Vector2i) -> void:
	if block_map.has(move) or not level.tile_has_floor(move):
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
	
func deal_base_damage(team: int):
	base_healthbars[team] -= 1
	if base_healthbars[team] <= 0:
		print("%s team loses" % team)
	
func add_to_bank(team: int, amount: int):
	base_banks[team] += amount
#endregion

#region Save and Load State
func _save_state() -> Dictionary:
	var save_state: Dictionary = {"blocks": {}, "lazers": [], "generators": [], "base_healthbars": {}, "base_banks": {} }
	for pos in block_map:
		save_state["blocks"][pos] = block_map[pos].get_path()
	for lazer in lazers:
		save_state["lazers"].append(lazer.get_path())
	for gen in generators:
		save_state["generators"].append(gen.get_path())
	save_state["base_healthbars"] = base_healthbars.duplicate()
	save_state["base_banks"] = base_banks.duplicate()
	return save_state
	
func _load_state(state: Dictionary) -> void:
	block_map.clear()
	lazers.clear()
	generators.clear()
	base_healthbars = state["base_healthbars"].duplicate()
	base_banks = state["base_banks"].duplicate()
	for pos in state["blocks"]:
		block_map[pos] = get_node(state["blocks"][pos])
	for lazer in state["lazers"]:
		lazers.append(get_node(lazer))
	for gen in state["generators"]:
		generators.append(get_node(gen))
	
#endregion
