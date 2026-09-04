extends CanvasLayer

const FOLDER_SELECT_SCREEN_PATH := "res://folder_select_screen.tscn"
const CodeParser = preload("res://code_parser.gd")
const StatParser = preload("res://stat_parser.gd")
const AbilityParser = preload("res://ability_parser.gd")

@export var note_texture_rect: TextureRect
@export var stat_ability_note: Texture2D
@export var guide_book: Control

@export var sword_preview: Control
@export var fire_overlay: AnimatedSprite2D

var target_character: String = "henry"
var save_path: String = ""

func _ready() -> void:
	CursorManager.use_default_cursor()
	save_path = "user://%s_code.json" % target_character
	$TitleBar.text = "C:\\%s>" % target_character.capitalize()

	_load_saved_code()

	$CodeTextEdit.text_changed.connect(_on_text_changed)
	$RunButton.pressed.connect(_on_run_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

	_update_currency_label()
	_update_note()
	_setup_sword_preview()

	if fire_overlay:
		fire_overlay.animation_finished.connect(_on_fire_animation_finished)

func _setup_sword_preview() -> void:
	if not sword_preview:
		return

	if target_character == "henry":
		sword_preview.visible = false
	else:
		sword_preview.visible = true
		var has_fire: bool = "burn" in WeaponEffectManager.active_effects
		fire_overlay.visible = has_fire
		if has_fire:
			fire_overlay.play("idle")

func _update_note() -> void:
	if target_character == "henry":
		if note_texture_rect:
			note_texture_rect.visible = true
			note_texture_rect.texture = stat_ability_note
		if guide_book:
			guide_book.visible = false
	else:
		if note_texture_rect:
			note_texture_rect.visible = false
		if guide_book:
			guide_book.visible = true

func _load_saved_code() -> void:
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()
			var data = JSON.parse_string(json_string)
			if data and data.has("code_text"):
				$CodeTextEdit.text = data["code_text"]

func _save_code() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var data := {"code_text": $CodeTextEdit.text}
		file.store_string(JSON.stringify(data))
		file.close()

func _on_text_changed() -> void:
	var current_length: int = CodeParser.count_significant_characters($CodeTextEdit.text)
	var remaining: int = CurrencyManager.character_count - current_length

	if remaining < 0:
		var max_allowed: int = CurrencyManager.character_count
		var trimmed_text: String = $CodeTextEdit.text

		while CodeParser.count_significant_characters(trimmed_text) > max_allowed:
			trimmed_text = trimmed_text.substr(0, trimmed_text.length() - 1)

		$CodeTextEdit.text = trimmed_text

		var lines: PackedStringArray = trimmed_text.split("\n")
		var last_line_index: int = lines.size() - 1
		var last_line_length: int = lines[last_line_index].length()

		$CodeTextEdit.set_caret_line(last_line_index)
		$CodeTextEdit.set_caret_column(last_line_length)

	_update_currency_label()
	_save_code()
	_check_live_sword_preview()

func _check_live_sword_preview() -> void:
	if target_character == "henry" or not sword_preview:
		return

	var text: String = $CodeTextEdit.text
	var has_import: bool = text.contains("import weapon_effect")
	var has_fire: bool = text.contains("weapon_effect = \"fire\"")

	if has_import and has_fire:
		if not fire_overlay.visible:
			fire_overlay.visible = true
			fire_overlay.play("ignite")
	else:
		fire_overlay.visible = false
		fire_overlay.stop()

func _update_currency_label() -> void:
	var current_length: int = CodeParser.count_significant_characters($CodeTextEdit.text)
	var remaining: int = CurrencyManager.character_count - current_length
	$CurrencyLabel.text = "Characters remaining: %d" % remaining

func _on_run_pressed() -> void:
	var code_text: String = $CodeTextEdit.text

	if target_character == "henry":
		_run_henry_code(code_text)
	else:
		_run_weapon_code(code_text)

func _run_henry_code(code_text: String) -> void:
	var first_line: String = _get_first_significant_line(code_text)

	if first_line == "import stat":
		_run_stat_code(code_text)
	elif first_line == "import henry_ability":
		_run_ability_code(code_text)
	else:
		$OutputLabel.text = "Compile failed:\n  Line 1: Unknown import. Use 'import stat' or 'import henry_ability'"

func _get_first_significant_line(code_text: String) -> String:
	var lines: PackedStringArray = code_text.split("\n")
	for line in lines:
		var trimmed: String = line.strip_edges()
		if trimmed != "":
			return trimmed
	return ""

func _run_stat_code(code_text: String) -> void:
	var result: Dictionary = StatParser.parse(code_text)

	if result["is_fully_valid"]:
		HenryStatManager.apply_stat_gains(result["gains"])
		$OutputLabel.text = "Compiled successfully.\nSpeed: +%.1f%%\nAttack Speed: +%.1f%%\nDexterity: +%.1f%%" % [HenryStatManager.speed_bonus_percent, HenryStatManager.attack_speed_bonus_percent, HenryStatManager.dexterity_bonus_percent]
	else:
		var error_text := "Compile failed:\n"
		for error in result["errors"]:
			error_text += "  Line %d: %s\n" % [error["line"], error["message"]]
		$OutputLabel.text = error_text

func _run_ability_code(code_text: String) -> void:
	var result: Dictionary = AbilityParser.parse(code_text)

	if result["is_fully_valid"]:
		HenryAbilityManager.unlock_ability()
		$OutputLabel.text = "Compiled successfully.\nAbility system unlocked! Hold Shift to run, Space to dodge."
	else:
		var error_text := "Compile failed:\n"
		for error in result["errors"]:
			error_text += "  Line %d: %s\n" % [error["line"], error["message"]]
		$OutputLabel.text = error_text

func _run_weapon_code(code_text: String) -> void:
	var result: Dictionary = CodeParser.parse(code_text)

	if result["is_fully_valid"]:
		var effects: Array[String] = []
		effects.assign(result["effects"])
		WeaponEffectManager.apply_valid_code(effects, result["character_count"])
		$OutputLabel.text = "Compiled successfully.\nActive effects: %s\nDamage bonus: %d" % [str(result["effects"]), WeaponEffectManager.damage_bonus]
		_play_run_fire("burn" in effects)
	else:
		WeaponEffectManager.apply_invalid_code(result["character_count"])
		var error_text := "Compile failed:\n"
		for error in result["errors"]:
			error_text += "  Line %d: %s\n" % [error["line"], error["message"]]
		error_text += "\nUsing damage bonus only (%d), no special effect active." % WeaponEffectManager.damage_bonus
		$OutputLabel.text = error_text

		var has_import: bool = code_text.contains("import weapon_effect")
		var has_fire: bool = code_text.contains("weapon_effect = \"fire\"")
		_play_run_fire(has_import and has_fire)

func _play_run_fire(is_active: bool) -> void:
	if not sword_preview:
		return

	if is_active:
		fire_overlay.visible = true
		fire_overlay.play("ignite")
	else:
		fire_overlay.visible = false
		fire_overlay.stop()

func _on_fire_animation_finished() -> void:
	if fire_overlay.animation == "ignite":
		fire_overlay.play("idle")

func _on_back_pressed() -> void:
	var folder_screen_scene: PackedScene = load(FOLDER_SELECT_SCREEN_PATH)
	var folder_screen := folder_screen_scene.instantiate()
	get_tree().root.add_child(folder_screen)
	queue_free()
