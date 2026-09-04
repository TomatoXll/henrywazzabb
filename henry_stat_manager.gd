extends Node

const SAVE_PATH := "user://henry_stats_save.json"

const STAT_CAPS := {
	"speed": 30.0,
	"speed_atk": 10.0,
	"dexterity": 40.0,
}

var speed_bonus_percent: float = 0.0
var attack_speed_bonus_percent: float = 0.0
var dexterity_bonus_percent: float = 0.0

func _ready() -> void:
	_load_stats()

func apply_stat_gains(gains: Dictionary) -> void:
	speed_bonus_percent = min(gains.get("speed", 0.0), STAT_CAPS["speed"])
	attack_speed_bonus_percent = min(gains.get("speed_atk", 0.0), STAT_CAPS["speed_atk"])
	dexterity_bonus_percent = min(gains.get("dexterity", 0.0), STAT_CAPS["dexterity"])
	_save_stats()

func reset_stats() -> void:
	speed_bonus_percent = 0.0
	attack_speed_bonus_percent = 0.0
	dexterity_bonus_percent = 0.0
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _save_stats() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {
			"speed_bonus_percent": speed_bonus_percent,
			"attack_speed_bonus_percent": attack_speed_bonus_percent,
			"dexterity_bonus_percent": dexterity_bonus_percent,
		}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_stats() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()
			var data = JSON.parse_string(json_string)
			if data:
				speed_bonus_percent = data.get("speed_bonus_percent", 0.0)
				attack_speed_bonus_percent = data.get("attack_speed_bonus_percent", 0.0)
				dexterity_bonus_percent = data.get("dexterity_bonus_percent", 0.0)
