class_name EnergyCollector
extends Block

# Psuedo Constant
var MAX_CHARGE: int = int(2.5 * Engine.physics_ticks_per_second)

# Saved State
var fake_gen_targets: Array[Lazer] = []
var fake_gen_timers: Array[int] = []

func _ready() -> void:
	add_to_group("network_sync")
	SyncManager.scene_despawned.connect(_on_scene_despawned)

func power_up() -> void:
	game_master.add_to_bank(team, 1)

func request_power(lazer: Lazer, power: int):
	for i in range(power):
		fake_gen_targets.append(lazer)

func _network_postprocess(_input: Dictionary) -> void:
	super(_input)
	fake_gen_timers.resize(fake_gen_targets.size())
	for i in range(fake_gen_timers.size()):
		fake_gen_timers[i] += 1
		if fake_gen_timers[i] >= MAX_CHARGE and fake_gen_targets[i] and fake_gen_targets[i].active:
			fake_gen_targets[i].power_up()
			game_master.add_to_bank(team, -1)
			fake_gen_timers[i] = 0

func _on_scene_despawned(_node_name: String, node: Node):
	for i in range(fake_gen_targets.size()):
		if fake_gen_targets[i] == node:
			fake_gen_targets[i] = null

func map_targets_to_paths(target: Lazer):
	if not target:
		return target
	else:
		return target.get_path()

func map_paths_to_targets(path):
	if path == null:
		return path
	else:
		return get_node(path)

func _save_state() -> Dictionary:
	var fake_gen_target_paths = fake_gen_targets.map(map_targets_to_paths)
	return {
		"fake_gen_timers": fake_gen_timers.duplicate(),
		"fake_gen_targets": fake_gen_target_paths
	}

func _load_state(state: Dictionary) -> void:
	fake_gen_timers = state["fake_gen_timers"].duplicate()
	fake_gen_targets.assign(state["fake_gen_targets"].map(map_paths_to_targets))
