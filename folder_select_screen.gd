extends CanvasLayer

const RESPAWN_SCREEN_PATH := "res://respawn_screen.tscn"
const CODE_EDITOR_PATH := "res://code_editor.tscn"

func _ready() -> void:
	CursorManager.use_default_cursor()
	$HenryFolderButton.pressed.connect(_open_code_editor.bind("henry"))
	$DarpFolderButton.pressed.connect(_open_code_editor.bind("Sword"))
	$BackButton.pressed.connect(_on_back_pressed)

func _open_code_editor(target_character: String) -> void:
	var editor_scene: PackedScene = load(CODE_EDITOR_PATH)
	var editor := editor_scene.instantiate()
	editor.target_character = target_character
	get_tree().root.add_child(editor)
	queue_free()

func _on_back_pressed() -> void:
	var respawn_scene: PackedScene = load(RESPAWN_SCREEN_PATH)
	var respawn_screen := respawn_scene.instantiate()
	get_tree().root.add_child(respawn_screen)
	queue_free()
