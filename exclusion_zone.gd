class_name ExclusionZone
extends Node2D

# Saved State
@export var growth_times = 2
@export var end_pos: Vector2i = Vector2i.ZERO:
	set(value):
		end_pos = value
		queue_redraw()

# Unsaved State
var tile_pos: Vector2i = Vector2i.ZERO
@export var team: Constants.Teams = Constants.Teams.RED
@export var growth_timer = 900
@export var growth_amount = Vector2i.ZERO
var grid: Grid = preload("res://Grid/Grid.tres")
var color: Color = Color(0.6, 0.0, 0.0)

@onready var network_timer: NetworkTimer = %NetworkTimer

func _draw() -> void:
	var rect = Rect2i(position, Vector2i.ZERO)
	rect.end = grid.grid_to_map(end_pos)
	rect = rect.abs().grow(32)
	rect.position -= Vector2i(position)
	draw_rect(rect, color, false, 4)

func _ready() -> void:
	color = PlayerColors.primary_color_map[team] * 0.6
	color.a = 1.0
	network_timer.wait_ticks = growth_timer
	network_timer.start()
	queue_redraw()

func is_colliding(pos: Vector2i):
	var x_is_colliding = pos.x >= min(tile_pos.x, end_pos.x) and pos.x <= max(tile_pos.x, end_pos.x)
	var y_is_colliding = pos.y >= min(tile_pos.y, end_pos.y) and pos.y <= max(tile_pos.y, end_pos.y)
	return x_is_colliding and y_is_colliding

func _on_network_timer_timeout() -> void:
	if growth_times > 0:
		end_pos += growth_amount
		growth_times -= 1

func _save_state() -> Dictionary:
	return {
		"growth_times": growth_times,
		"end_pos": end_pos
	}

func _load_state(state: Dictionary) -> void:
	growth_times = state["growth_times"]
	end_pos = state["end_pos"]
