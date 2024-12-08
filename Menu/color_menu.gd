extends Control

@onready var red: ColorRect = %Red
@onready var blue: ColorRect = %Blue
@onready var orange: ColorRect = %Orange
@onready var cyan: ColorRect = %Cyan
@onready var yellow: ColorRect = %Yellow
@onready var purple: ColorRect = %Purple
@onready var maroon: ColorRect = %Maroon
@onready var brown: ColorRect = %Brown
@onready var primary: ColorRect = %Primary
@onready var secondary: ColorRect = %Secondary

var selecting_primary: bool = true:
	set(value):
		selecting_primary = value
		if value:
			primary.scale = Vector2(1.3, 1.3)
			secondary.scale = Vector2.ONE
		else:
			primary.scale = Vector2.ONE
			secondary.scale = Vector2(1.3, 1.3)

func _ready() -> void:
	primary.color = Lobby.primary_color
	secondary.color = Lobby.secondary_color
	selecting_primary = true

func _on_back_button_pressed() -> void:
	ConfigFileHandler.save_color_to_cfg()
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")

func set_color(color: Color):
	if selecting_primary:
		if secondary.color == color:
			return
		Lobby.primary_color = color
		primary.color = color
	else:
		if primary.color == color:
			return
		Lobby.secondary_color = color
		secondary.color = color

func _on_red_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(red.color)

func _on_blue_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(blue.color)

func _on_orange_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(orange.color)

func _on_cyan_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(cyan.color)

func _on_yellow_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(yellow.color)

func _on_purple_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(purple.color)

func _on_maroon_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(maroon.color)

func _on_brown_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	set_color(brown.color)

func _on_primary_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	selecting_primary = true

func _on_secondary_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var eventmouse = event as InputEventMouseButton
	if eventmouse.button_index != MOUSE_BUTTON_LEFT:
		return
	selecting_primary = false
