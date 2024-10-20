class_name Lazer
extends Block

@onready var damage_particles: CPUParticles2D = %DamageParticles

# Saved State
var charge: int = 0
var facing: Vector2i = Vector2i.RIGHT

# Pseudo Constant
var MAX_CHARGE: int = 3 * Engine.physics_ticks_per_second

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
	damage_particles.emitting = true
	damage_particles.visible = true
	draw_line(start_pos, end_pos, color, 16)

func _network_spawn(data: Dictionary) -> void:
	super(data)
	if team == 1:
		facing = Vector2i.RIGHT
	else:
		facing = Vector2i.LEFT
	MAX_HEALTH = 5 * Engine.physics_ticks_per_second
	health = MAX_HEALTH

#region Virtual Block Functions
func interact(player: Player) -> void:
	if player.team != team:
		return
	if player.held_block:
		return
	target_pos = Vector2i.MIN
	charge = 0
	game_master.move_block_to_hand(player, self)
	
func place(player: Player, pos: Vector2i) -> void:
	game_master.move_hand_to_field(player, pos)

func get_connection_directions() -> Array[Vector2i]:
	var all_directions = super()
	all_directions.erase(facing)
	return all_directions
#endregion

#region Public Functions
# Generator calls this when it sends power to us
func power_up() -> void:
	charge = MAX_CHARGE

# Game master calls this during the shooting step
func shoot() -> void:
	if charge <= 0:
		target_pos = Vector2i.MIN
		return
	charge -= 1
	var starting_pos = tile_pos + facing
	var current_pos = starting_pos
	while game_master.lazer_can_pass(current_pos):
		current_pos += facing
	var target = game_master.get_block_at_pos(current_pos)
	target_pos = calculate_collision_point(current_pos)
	if not target or target.team == team:
		return
	if target is Lazer and lazer_should_collide(target):
		target_pos = calculate_lazer_collision_point(current_pos)
		return
	target.damage()
#endregion

#region Private Functions
func calculate_lazer_collision_point(other_lazer_tile_pos: Vector2i) -> Vector2i:
	return lerp(Vector2(calculate_nose_point()), Vector2(calculate_collision_point(other_lazer_tile_pos)), 0.5)

func calculate_collision_point(collision_tile_pos: Vector2i) -> Vector2i:
	var map_pos = grid.grid_to_map(collision_tile_pos)
	return map_pos + grid.HALF_SIZE * -facing
	
func calculate_nose_point() -> Vector2i:
	return grid.grid_to_map(tile_pos) + grid.HALF_SIZE * facing

func lazer_should_collide(lazer: Lazer) -> bool:
	return lazer.facing == -facing and lazer.charge > 0
#endregion

#region Save and Load State
func _save_state() -> Dictionary:
	var state: Dictionary = {}
	save_block_state(state)
	state["facing"] = facing
	state["charge"] = charge
	return state

func _load_state(state: Dictionary) -> void:
	load_block_state(state)
	charge = state["charge"]
	facing = state["facing"]
#endregion
