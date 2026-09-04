extends CanvasLayer

const CHARACTER_SELECT_SCREEN_PATH := "res://character_select_screen.tscn"
const START_SCREEN_PATH := "res://start_screen.tscn"
const WARNING_SCREEN_PATH := "res://warning_screen.tscn"

func _ready() -> void:
	CursorManager.use_default_cursor()
	$Respawn.pressed.connect(_on_respawn_pressed)
	$BackToMenu.pressed.connect(_on_back_to_menu_pressed)
	$EditButton.pressed.connect(_on_edit_pressed)
	$CodeFolderButton.pressed.connect(_on_code_folder_pressed)
	$CurrencyLabel.text = "Characters: %d" % CurrencyManager.character_count

func _on_respawn_pressed() -> void:
	if _try_open_warning("respawn"):
		return
	await _check_low_durability_warning("respawn")

	get_tree().paused = false
	CorruptionManager.reset_hit_count()
	queue_free()
	get_tree().reload_current_scene()

func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(START_SCREEN_PATH)
	queue_free()

func _on_edit_pressed() -> void:
	if _try_open_warning("edit"):
		return
	await _check_low_durability_warning("edit")

	PlayerStatus.clear_deformation()

	var character_select_scene: PackedScene = load(CHARACTER_SELECT_SCREEN_PATH)
	var character_select := character_select_scene.instantiate()
	get_tree().root.add_child(character_select)
	queue_free()

func _on_code_folder_pressed() -> void:
	if _try_open_warning("folder"):
		return
	await _check_low_durability_warning("folder")

	var folder_screen_scene: PackedScene = load("res://folder_select_screen.tscn")
	var folder_screen := folder_screen_scene.instantiate()
	get_tree().root.add_child(folder_screen)
	queue_free()

func _try_open_warning(element_name: String) -> bool:
	if not CorruptionManager.is_element_broken(element_name):
		return false

	var warning_scene: PackedScene = load(WARNING_SCREEN_PATH)
	var warning_screen := warning_scene.instantiate()
	warning_screen.target_element = element_name
	get_tree().root.add_child(warning_screen)
	return true

func _check_low_durability_warning(element_name: String) -> void:
	if not CorruptionManager.is_element_low(element_name):
		return

	get_tree().paused = true

	var warning_scene: PackedScene = load(WARNING_SCREEN_PATH)
	var warning_screen := warning_scene.instantiate()
	warning_screen.target_element = element_name
	warning_screen.severity = "low"
	get_tree().root.add_child(warning_screen)

	await warning_screen.closed
