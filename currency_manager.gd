extends Node

const SAVE_PATH := "user://currency_save.json"

var character_count: int = 0

func _ready() -> void:
	_load_currency()

func add_characters(amount: int) -> void:
	character_count += amount
	_save_currency()

func spend_characters(amount: int) -> bool:
	if character_count >= amount:
		character_count -= amount
		_save_currency()
		return true
	return false

func _save_currency() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {"character_count": character_count}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_currency() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()
			var data = JSON.parse_string(json_string)
			if data and data.has("character_count"):
				character_count = data["character_count"]
				
func reset_currency() -> void:
	character_count = 0
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
