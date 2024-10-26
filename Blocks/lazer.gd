class_name Lazer
extends Block

@onready var damage_particles: CPUParticles2D = %DamageParticles

# Saved State
var charge: Array[int] = [0]
var facing: Vector2i = Vector2i.RIGHT
var level: int = 1:
	set(value):
		level = value
		charge.resize(2 * level - 1)

var front_lazer: Lazer = null:
	set(value):
		if front_lazer == value:
			return
		if front_lazer:
			front_lazer.deregistered.disconnect(_on_front_lazer_deregistered)
		if value:
			value.deregistered.connect(_on_front_lazer_deregistered)
		front_lazer = value

# Unsaved State
var requested_energy: bool = false:
	get:
		if front_lazer:
			return front_lazer.requested_energy
		return requested_energy
	set(value):
		requested_energy = value
		if front_lazer:
			front_lazer.requested_energy = value

# Pseudo Constant
var MAX_CHARGE: int = 3 * Engine.physics_ticks_per_second
var red_team_super_back_texture = preload("res://Assets/Red/Super_Lazer_Back_-_Red_64x64.png")
var red_team_super_front_texture = preload("res://Assets/Red/Super_Lazer_Front_-_Red_64x64.png")
var blue_team_super_back_texture = preload("res://Assets/Blue/Super_Lazer_Back_-_Blue_64x64.png")
var blue_team_super_front_texture = preload("res://Assets/Blue/Super_Lazer_Front_-_Blue_64x64.png")

signal deregistered

var target_pos: Vector2i = Vector2i.MIN:
	set(value):
		target_pos = value
		queue_redraw()

func _draw() -> void:
	if target_pos == Vector2i.MIN:
		damage_particles.emitting = false
		damage_particles.visible = false
		return
	var start_pos = facing * grid.HALF_SIZE
	var end_pos = target_pos - Vector2i(position)
	var color = Color(1, 0, 0) if team == Constants.Teams.RED else Color(0, 0, 1)
	damage_particles.position = end_pos
	damage_particles.direction = -facing
	if damage_particles.amount != 60 * level:
		damage_particles.amount = 60 * level
	damage_particles.emission_rect_extents.y = 8 * level
	damage_particles.emitting = true
	damage_particles.visible = true
	draw_line(start_pos, end_pos, color, 16 * level)

func _network_spawn(data: Dictionary) -> void:
	super(data)
	if team == 1:
		facing = Vector2i.RIGHT
	else:
		facing = Vector2i.LEFT
	MAX_HEALTH = 5 * Engine.physics_ticks_per_second
	health = MAX_HEALTH
	sell_price = 5

#region Virtual Block Functions
func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		return
	game_master.move_block_to_hand(player, self)
	
func place(player: Player, pos: Vector2i) -> void:
	game_master.move_hand_to_field(player, pos)
	var back_pos = pos - facing
	var front_pos = pos + facing
	var back_block = game_master.get_block_at_pos(back_pos)
	var front_block = game_master.get_block_at_pos(front_pos)
	if back_block is Lazer and can_connect_to_lazer(back_block):
		connect_to_lazer_from_front(back_block)
	elif front_block is Lazer and can_connect_to_lazer(front_block):
		connect_to_lazer_from_back(front_block)
		
func get_connection_directions() -> Array[Vector2i]:
	var all_directions = super()
	if not front_lazer:
		all_directions.erase(facing)
	return all_directions

func deregister():
	deregistered.emit()
	target_pos = Vector2i.MIN
	clear_charge()
	level = 1
	if front_lazer:
		front_lazer.level = 1
		front_lazer = null
#endregion

#region Public Functions
func get_energy_requirement() -> int:
	var effective_level = level
	if front_lazer:
		effective_level = front_lazer.level
	return effective_level * 2 - 1

# Generator calls this when it sends power to us
func power_up() -> void:
	if front_lazer:
		front_lazer.power_up()
		return
	var min_index = find_min_charge_index()
	charge[min_index] = MAX_CHARGE

# Game master calls this during the shooting step
func shoot() -> void:
	if front_lazer:
		target_pos = Vector2i.MIN
		return
	decrement_charge()
	if charge_empty():
		target_pos = Vector2i.MIN
		return
	var starting_pos = tile_pos + facing
	var current_pos = starting_pos
	while game_master.lazer_can_pass(current_pos):
		current_pos += facing
	var target = game_master.get_block_at_pos(current_pos)
	target_pos = calculate_collision_point(current_pos)
	if not target or target.team == team:
		return
	if target is Lazer:
		if lazer_should_collide(target):
			target_pos = calculate_lazer_collision_point(current_pos)
			return
		if should_be_overpowered_by(target):
			target_pos = calculate_collision_point(tile_pos + facing)
			return
	target.damage(level)
#endregion

#region Private Functions
func clear_charge() -> void:
	charge.resize(1)
	charge[0] = 0

func decrement_charge() -> void:
	for i in range(charge.size()):
		charge[i] -= 1

func charge_empty() -> bool:
	for value in charge:
		if value <= 0:
			return true
	return false

func find_min_charge_index() -> int:
	var min_index = 0
	for i in range(1, charge.size()):
		if charge[i] < charge[min_index]:
			min_index = i
	return min_index

func connect_to_lazer_from_back(lazer: Lazer) -> void:
	front_lazer = lazer
	lazer.level = 2

func connect_to_lazer_from_front(lazer: Lazer) -> void:
	lazer.front_lazer = self
	level = 2

func can_connect_to_lazer(lazer: Lazer) -> bool:
	return lazer.team == team and lazer.facing == facing and not lazer.front_lazer and lazer.level == 1

func calculate_lazer_collision_point(other_lazer_tile_pos: Vector2i) -> Vector2i:
	return lerp(Vector2(calculate_nose_point()), Vector2(calculate_collision_point(other_lazer_tile_pos)), 0.5)

func calculate_collision_point(collision_tile_pos: Vector2i) -> Vector2i:
	var map_pos = grid.grid_to_map(collision_tile_pos)
	return map_pos + grid.HALF_SIZE * -facing
	
func calculate_nose_point() -> Vector2i:
	return grid.grid_to_map(tile_pos) + grid.HALF_SIZE * facing

func lazer_should_collide(lazer: Lazer) -> bool:
	return lazer.facing == -facing and not lazer.charge_empty() and lazer.level == level
	
func should_be_overpowered_by(lazer: Lazer) -> bool:
	return lazer.facing == -facing and not lazer.charge_empty() and lazer.level > level
#endregion

func _network_postprocess(_input: Dictionary) -> void:
	super(_input)
	if level == 2 and not front_lazer:
		sprite.texture = red_team_super_front_texture if team == Constants.Teams.RED else blue_team_super_front_texture
	elif front_lazer:
		sprite.texture = red_team_super_back_texture if team == Constants.Teams.RED else blue_team_super_back_texture
	else:
		sprite.texture = red_team_texture if team == Constants.Teams.RED else blue_team_texture

#region Save and Load State
func _save_state() -> Dictionary:
	var state: Dictionary = {}
	save_block_state(state)
	state["facing"] = facing
	state["charge"] = charge.duplicate()
	if front_lazer:
		state["front_lazer"] = front_lazer.get_path()
	else:
		state["front_lazer"] = null
	state["level"] = level
	return state

func _load_state(state: Dictionary) -> void:
	load_block_state(state)
	charge = state["charge"].duplicate()
	facing = state["facing"]
	if state["front_lazer"]:
		front_lazer = get_node(state["front_lazer"])
	else:
		front_lazer = null
	level = state["level"]
#endregion

func _on_front_lazer_deregistered():
	front_lazer = null
