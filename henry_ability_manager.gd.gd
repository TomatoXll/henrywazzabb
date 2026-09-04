extends Node

const SAVE_PATH := "user://henry_ability_save.json"

var is_ability_unlocked: bool = false
var max_stamina: float = 100.0
var current_stamina: float = 100.0

var is_running: bool = false
var run_stamina_cost_per_second: float = 5.0
var dodge_stamina_cost: float = 15.0
var stamina_regen_per_second: float = 5.0

signal dodge_triggered

func _ready() -> void:
	_load_ability()

func unlock_ability() -> void:
	is_ability_unlocked = true
	current_stamina = max_stamina
	_save_ability()

func reset_ability() -> void:
	is_ability_unlocked = false
	current_stamina = max_stamina
	is_running = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func try_start_run() -> bool:
	if current_stamina < run_stamina_cost_per_second:
		return false
	is_running = true
	return true

func stop_run() -> void:
	is_running = false

func try_dodge() -> bool:
	if current_stamina < dodge_stamina_cost:
		return false
	current_stamina = max(current_stamina - dodge_stamina_cost, 0.0)
	dodge_triggered.emit()
	return true

func process_tick(delta: float) -> void:
	if not is_ability_unlocked:
		return

	if is_running:
		current_stamina = max(current_stamina - run_stamina_cost_per_second * delta, 0.0)
		if current_stamina <= 0.0:
			is_running = false
	elif current_stamina < max_stamina:
		current_stamina = min(current_stamina + stamina_regen_per_second * delta, max_stamina)

func _save_ability() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {"is_ability_unlocked": is_ability_unlocked}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_ability() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()
			var data = JSON.parse_string(json_string)
			if data:
				is_ability_unlocked = data.get("is_ability_unlocked", false)
				if is_ability_unlocked:
					current_stamina = max_stamina
