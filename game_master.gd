class_name GameMaster
extends Node

var grid: Grid = preload("res://Grid/Grid.tres")
@export var level: Level

@onready var end_timer: NetworkTimer = %EndTimer

#TODO remove base code from the gamemaster, it's kinda weird for it to be here

# Saved State
var lazers: Array[Lazer]
var generators: Array[Generator]
var block_map: Dictionary
var base_healthbars: Dictionary = {1: 30 * Engine.physics_ticks_per_second, 2: 30 * Engine.physics_ticks_per_second }
var base_banks: Dictionary = {1: 15, 2: 15}
var base_net_energy: Dictionary = {1: 0, 2: 0}
var current_tick: int = 0

# Unsaved State
# Temporary Values, only last for a single frame
var allowed_move: Dictionary
var desired_moves: Dictionary
var desired_interacts: Dictionary

# This doesn't have to go into state because it's constant throughout a match
var collectors: Array[EnergyCollector]
var players: Array[Player]
var exclusion_zones: Array[ExclusionZone]

# for test game only
var left_player = 1
var right_player = 2
var player1bank: Label = null
var player2bank: Label = null
var start_timer: Label = null
var end_game_label: Label = null

func _process(_delta: float) -> void:
	if base_net_energy[left_player] < 0:
		player1bank.text = "%s %s" % [base_banks[left_player], base_net_energy[left_player]]
	else:
		player1bank.text = "%s +%s" % [base_banks[left_player], base_net_energy[left_player]]
	if base_net_energy[right_player] < 0:
		player2bank.text = "%s %s" % [base_banks[right_player], base_net_energy[right_player]]
	else:
		player2bank.text = "%s +%s" % [base_banks[right_player], base_net_energy[right_player]]
	if current_tick < 90:
		var time = ceil(float(90 - current_tick) / 30)
		start_timer.text = "%s!" % time
	else:
		start_timer.visible = false
	

func _ready() -> void:
	SyncManager.sync_started.connect(_on_sync_started)
	end_timer.timeout.connect(stop)
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
		if child is ExclusionZone:
			exclusion_zones.append(child)
			child.tile_pos = grid.map_to_grid(child.position)
			child.position = grid.grid_to_map(child.tile_pos)

# Anything that needs to happen in a strict order should be managed by the game master in this function
# network_processes in other classes should either be network_preprocess or network_postprocess
# so that they explicitly occur before or after this function
# also preprocess and postprocess functions should only contain things that are either purely visual
# or will always happen regardless of any intervening events
func _network_process(_input: Dictionary) -> void:
	if not end_timer.is_stopped():
		return
	current_tick += 1
	if current_tick <= 90:
		desired_moves.clear()
		return
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
	
	if current_tick % 5 == 0:
		for generator in generators:
			generator.target = null
		for collector in collectors:
			collector.fake_gen_targets.clear()
		for lazer in lazers:
			lazer.requested_energy = false
		base_net_energy[1] = 0
		base_net_energy[2] = 0
		for lazer in lazers:
			if lazer.requested_energy:
				continue
			lazer.requested_energy = true
			request_power(lazer)
		for collector in collectors:
			var found_gens = find_power_sources(collector, 0, false)
			base_net_energy[collector.team] += found_gens.size()
			for gen in found_gens:
				gen.target = collector
	for lazer in lazers:
		lazer.shoot()
	# Iterate over the .keys() because entries can get removed here
	for pos in block_map.keys():
		if block_map[pos].should_destroy():
			block_map[pos].destroy()
	
	for player in players:
		if player.health <= 0 and SyncManager.ensure_current_tick_input_complete():
			end_game_label.visible = true
			end_game_label.text = "Team %s loses!" % player.team
			player.state = player.STATES.DEAD
			end_game()
			break
	
#region Private Functions
func is_excluded(team: Constants.Teams, move: Vector2i) -> bool:
	for zone in exclusion_zones:
		if zone.team == team:
			continue
		if zone.is_colliding(move):
			return true
	return false

func has_player(pos: Vector2i) -> bool:
	for player in players:
		if player.tile_pos == pos:
			return true
	return false

func request_power(lazer: Lazer):
	var power_requested = lazer.get_energy_requirement()
	var found_gens = find_power_sources(lazer, power_requested, true)
	var base: EnergyCollector = null
	if found_gens.size() == 0:
		return
	if found_gens.back() is EnergyCollector:
		base = found_gens.back()
	if found_gens.size() < power_requested and not base:
		return
	# Pick oldest gens first
	var power_received = 0
	for generator in generators:
		if found_gens.has(generator):
			generator.target = lazer
			power_received += 1
			if power_received == power_requested:
				break
	if power_received < power_requested and base:
		base.request_power(lazer, power_requested - power_received)
		base_net_energy[lazer.team] -= power_requested - power_received

func find_power_sources(block: Block, number_to_find: int, stop_at_closest: bool) -> Array:
	var queue = [block.tile_pos]
	var seen: Dictionary = { block.tile_pos: true }
	var team = block.team
	var base: EnergyCollector = null
	var result = []
	while queue.size() > 0:
		var pos = queue.pop_front()
		if block_map[pos] is Generator and block_map[pos].target == null and is_reactor_spot(pos):
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

func end_game() -> void:
	end_timer.start()

func stop() -> void:
	if SyncManager.network_adaptor.is_network_host():
		SyncManager.stop()
#endregion

#region Public Functions
func is_reactor_spot(pos: Vector2i) -> bool:
	return level.reactor_at_tile_pos(pos)

func get_base_health(team: int) -> int:
	return base_healthbars[team]

func tile_occupied(pos: Vector2i) -> bool:
	return has_player(pos) or block_map.has(pos)

func lazer_can_pass(pos: Vector2i) -> bool:
	return not tile_occupied(pos) and level.tile_has_floor(pos)

func get_player_at_pos(pos: Vector2i):
	for player in players:
		if player.tile_pos == pos:
			return player
	return null

func get_damageable_at_pos(pos: Vector2i):
	if block_map.has(pos):
		return block_map[pos]
	var player = get_player_at_pos(pos)
	return player

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
	block_map[pos].deregister()
	if block_map[pos] is Lazer:
		lazers.erase(block_map[pos])
	elif block_map[pos] is Generator:
		generators.erase(block_map[pos])
	block_map.erase(pos)
	

func register_desired_move(player: Player, move: Vector2i) -> void:
	if block_map.has(move) or not level.tile_has_floor(move) or is_excluded(player.team, move):
		allowed_move[player] = false
		return
	desired_moves[move] = desired_moves.get_or_add(move, 0) + 1
	allowed_move[player] = true

func register_desired_interact(player: Player, interact: Vector2i) -> void:
	if current_tick <= 90:
		return
	desired_interacts[player] = interact

func move_block_to_hand(player: Player, block: Block) -> void:
	player.held_block = block
	block.active = false
	deregister_block(block.tile_pos)
	
func move_hand_to_field(player: Player, pos: Vector2i) -> void:
	var block = player.held_block
	register_block(block, pos)
	player.held_block = null
	
func deal_base_damage(team: int, amount: int):
	base_healthbars[team] -= amount
	if base_healthbars[team] <= 0 and SyncManager.ensure_current_tick_input_complete():
		end_game_label.visible = true
		end_game_label.text = "Team %s loses!" % team
		end_game()

func get_bank_amount(team: int) -> int:
	return base_banks[team]

func remove_from_bank(team: int, amount: int):
	base_banks[team] = max(base_banks[team] - amount, 0)

func add_to_bank(team: int, amount: int):
	base_banks[team] = min(base_banks[team] + amount, 35)
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
	save_state["current_tick"] = current_tick
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
	current_tick = state["current_tick"]
	
#endregion

func _on_sync_started() -> void:
	start_timer.visible = true
