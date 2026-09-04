extends Node

const SAVE_PATH := "user://weapon_effects_save.json"
const DAMAGE_PER_CHARACTER := 0.2

var active_effects: Array[String] = []
var damage_bonus: int = 0

func _ready() -> void:
	_load_effects()

func apply_valid_code(effects: Array[String], character_count: int) -> void:
	active_effects = effects.duplicate()
	damage_bonus = int(character_count * DAMAGE_PER_CHARACTER)
	_save_effects()

func apply_invalid_code(character_count: int) -> void:
	active_effects.clear()
	damage_bonus = int(character_count * DAMAGE_PER_CHARACTER)
	_save_effects()

func reset_effects() -> void:
	active_effects.clear()
	damage_bonus = 0
	_save_effects()

func has_effect(effect_name: String) -> bool:
	return active_effects.has(effect_name)

func _save_effects() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {
			"active_effects": active_effects,
			"damage_bonus": damage_bonus,
		}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_effects() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()
			var data = JSON.parse_string(json_string)
			if data:
				if data.has("active_effects"):
					active_effects.assign(data["active_effects"])
				if data.has("damage_bonus"):
					damage_bonus = data["damage_bonus"]
