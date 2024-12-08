extends Control

@onready var action_list: VBoxContainer = %ActionList

var action_rebind_button_scene = preload("res://Menu/action_rebind_button.tscn")
var current_rebind_button: Button = null

var input_map = {
	"player1_up": "Move Up",
	"player1_down": "Move Down",
	"player1_left": "Move Left",
	"player1_right": "Move Right",
	"player1_turnup": "Turn Up",
	"player1_turnleft": "Turn Left",
	"player1_turnright": "Turn Right",
	"player1_turndown": "Turn Down"
}

func _ready() -> void:
	populate_action_list()
	
func populate_action_list():
	for action in input_map:
		var button = action_rebind_button_scene.instantiate()
		button.internal_action_name = action
		button.action_name_text = input_map[action]
		button.pressed.connect(_on_action_rebind_pressed.bind(button))
		action_list.add_child(button)
		button.update_text()

func _on_action_rebind_pressed(button: Button) -> void:
	if current_rebind_button:
		current_rebind_button.update_text()
	current_rebind_button = button
	current_rebind_button.start_rebinding()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if current_rebind_button:
		var action = current_rebind_button.internal_action_name
		event.keycode = KEY_NONE
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		current_rebind_button.update_text()
		current_rebind_button = null

func _on_back_button_pressed() -> void:
	ConfigFileHandler.save_input_to_cfg()
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")
