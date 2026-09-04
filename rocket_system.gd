extends Node

signal rocket_broken
signal rocket_repaired
signal height_reached_zero

@export var max_hit_count: int = 20
@export var height_rise_rate: float = 5.0
@export var height_fall_rate: float = 5.0

var current_height: float = 0.0
var current_hits: int = 0
var is_broken: bool = false
var is_game_over: bool = false

func _process(delta: float) -> void:
	if is_game_over:
		return

	if is_broken:
		current_height -= height_fall_rate * delta
	else:
		current_height += height_rise_rate * delta

	current_height = max(current_height, 0.0)

	if current_height <= 0.0 and not is_game_over:
		is_game_over = true
		height_reached_zero.emit()

func register_rocket_hit() -> void:
	if is_broken:
		return

	current_hits += 1

	if current_hits >= max_hit_count:
		is_broken = true
		rocket_broken.emit()

func repair_rocket() -> void:
	current_hits = 0
	is_broken = false
	rocket_repaired.emit()

func reset() -> void:
	current_height = 0.0
	current_hits = 0
	is_broken = false
	is_game_over = false
