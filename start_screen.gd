extends Node2D

const MAIN_SCENE_PATH := "res://main.tscn"
@export var hold_duration: float = 3.0

var current_cartridge_type: String = ""
var is_ready_to_start: bool = false
var is_holding: bool = false
var hold_time: float = 0.0

func _ready() -> void:
	$Console.cartridge_inserted.connect(_on_cartridge_inserted)
	$Console.cartridge_ejected.connect(_on_cartridge_ejected)
	$StartPrompt.visible = false
	$HoldProgress.visible = false
	$LeaveButton.pressed.connect(_on_leave_pressed)

func _on_cartridge_inserted(cartridge_type: String) -> void:
	current_cartridge_type = cartridge_type
	is_ready_to_start = true
	is_holding = false
	hold_time = 0.0

	if cartridge_type == "new_game":
		$StartPrompt.text = "HOLD X TO START"
	else:
		$StartPrompt.text = "PRESS ANY BUTTON TO START"

	$StartPrompt.visible = true

func _on_cartridge_ejected(_cartridge_type: String) -> void:
	is_ready_to_start = false
	is_holding = false
	current_cartridge_type = ""
	hold_time = 0.0
	$StartPrompt.visible = false
	$HoldProgress.visible = false

func _process(delta: float) -> void:
	if not is_ready_to_start:
		return

	if current_cartridge_type == "new_game":
		_process_hold(delta)
	else:
		_blink_prompt()

func _blink_prompt() -> void:
	$StartPrompt.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0)

func _process_hold(delta: float) -> void:
	if Input.is_key_pressed(KEY_X):
		is_holding = true
		hold_time += delta

		var remaining: float = hold_duration - hold_time
		var countdown_number: int = int(ceil(remaining))

		if countdown_number <= 0:
			_start_new_game()
			return

		$StartPrompt.modulate.a = 1.0
		$StartPrompt.text = str(countdown_number)
	else:
		if is_holding:
			is_holding = false
			hold_time = 0.0
			$StartPrompt.text = "HOLD X TO START"

		_blink_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not is_ready_to_start or current_cartridge_type != "load_game":
		return

	if event is InputEventKey and event.pressed:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()

func _start_new_game() -> void:
	_clear_save_data()
	_start_game()

func _clear_save_data() -> void:
	CorruptionManager.reset()
	CurrencyManager.reset_currency()
	WeaponEffectManager.reset_effects()
	HenryStatManager.reset_stats()
	HenryAbilityManager.reset_ability()

	var files_to_delete := [
		"user://henry_code.json",
		"user://darp_code.json",
	]
	for path in files_to_delete:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	_clear_directory("user://henry_custom")
	_clear_directory("user://darp_custom")

func _clear_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

func _start_game() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
func _on_leave_pressed() -> void:
	get_tree().quit()
