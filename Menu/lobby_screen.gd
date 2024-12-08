extends Control

@onready var player_labels: VBoxContainer = %PlayerLabels
@onready var start_button: Button = %StartButton

var player_label_scene = preload("res://Menu/player_label.tscn")

func _ready() -> void:
	Lobby.player_joined.connect(update_player_labels)
	Lobby.player_disconnected.connect(update_player_labels)
	update_player_labels()


func update_player_labels():
	for child in player_labels.get_children():
		child.queue_free()
	for player in Lobby.players:
		var player_label = player_label_scene.instantiate()
		player_label.text = Lobby.players[player]["name"]
		player_labels.add_child(player_label)
	if Lobby.players.size() >= 2 and multiplayer.is_server():
		start_button.disabled = false
	else:
		start_button.disabled = true


func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		Lobby.start_match.rpc()
