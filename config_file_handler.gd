extends Node

const config_path = "user://settings.ini"

var cfg = ConfigFile.new()

var name_mapping = {
	"MoveUp": "player1_up",
	"MoveDown": "player1_down",
	"MoveLeft": "player1_left",
	"MoveRight": "player1_right",
	"TurnUp": "player1_turnup",
	"TurnDown": "player1_turndown",
	"TurnLeft": "player1_turnleft",
	"TurnRight": "player1_turnright",
}

var reverse_mapping: Dictionary = {}

func _ready() -> void:
	for key in name_mapping:
		reverse_mapping[name_mapping[key]] = key
	
	if not FileAccess.file_exists(config_path):
		cfg.set_value("Keybindings", "MoveUp", "W")
		cfg.set_value("Keybindings", "MoveDown", "S")
		cfg.set_value("Keybindings", "MoveRight", "D")
		cfg.set_value("Keybindings", "MoveLeft", "A")
		cfg.set_value("Keybindings", "TurnUp", "I")
		cfg.set_value("Keybindings", "TurnDown", "K")
		cfg.set_value("Keybindings", "TurnLeft", "J")
		cfg.set_value("Keybindings", "TurnRight", "L")
		cfg.save(config_path)
	else:
		cfg.load(config_path)
		load_input_from_cfg()

func load_input_from_cfg():
	for key in cfg.get_section_keys("Keybindings"):
		var action_name = name_mapping.get(key)
		if not action_name:
			continue
		var cfgvalue = cfg.get_value("Keybindings", key)
		var event = InputEventKey.new()
		event.keycode = OS.find_keycode_from_string(cfgvalue)
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)

func save_input_to_cfg():
	for key in reverse_mapping:
		var events = InputMap.action_get_events(key)
		if events.size() > 0:
			cfg.set_value("Keybindings", reverse_mapping[key], OS.get_keycode_string(events[0].keycode))
	cfg.save(config_path)
