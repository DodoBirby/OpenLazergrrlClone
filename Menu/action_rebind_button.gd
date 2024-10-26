extends Button

@onready var action_name: Label = %ActionName
@onready var action_key: Label = %ActionKey

var internal_action_name: String = ""
var action_name_text: String = ""


func _ready() -> void:
	action_name.text = action_name_text

func update_text():
	var events = InputMap.action_get_events(internal_action_name)
	if events.size() > 0:
		action_key.text = events[0].as_text().trim_suffix(" (Physical)")
	else:
		action_key.text = "Unbound"

func start_rebinding():
	action_key.text = "Rebinding..."
