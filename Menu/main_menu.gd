extends Control

@onready var player_name_field: LineEdit = %PlayerNameField
@onready var host_port_field: LineEdit = %HostPortField
@onready var ip_field: LineEdit = %IpField
@onready var port_field: LineEdit = %PortField
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	Lobby.failed_to_connect.connect(_on_failed_to_connect)

func _on_host_button_pressed() -> void:
	Lobby.player_name = player_name_field.text
	Lobby.host_lobby(int(host_port_field.text))
	get_tree().change_scene_to_file("res://Menu/lobby_screen.tscn")

func _on_join_button_pressed() -> void:
	Lobby.player_name = player_name_field.text
	Lobby.join_lobby(ip_field.text, int(port_field.text))
	visible = false

func _on_failed_to_connect():
	visible = true
	status_label.text = "Failed to connect"

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/options_menu.tscn")
