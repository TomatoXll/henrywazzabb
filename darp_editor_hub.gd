extends CanvasLayer

const CHARACTER_SELECT_SCREEN_PATH := "res://character_select_screen.tscn"
const PIXEL_EDITOR_PATH := "res://pixel_editor.tscn"

const ANIMATION_CONFIG := {
	"attack": {
		"frame_count": 6,
		"canvas_width": 60,
		"canvas_height": 80,
		"source": "player",
	},
	"slash": {
		"frame_count": 8,
		"canvas_width": 20,
		"canvas_height": 50,
		"source": "slash_attack",
	},
}

func _ready() -> void:
	CursorManager.use_default_cursor()
	$AttackButton.pressed.connect(_open_editor.bind("attack"))
	$SlashEffectButton.pressed.connect(_open_editor.bind("slash"))
	$BackButton.pressed.connect(_on_back_pressed)

func _open_editor(animation_name: String) -> void:
	var config: Dictionary = ANIMATION_CONFIG[animation_name]

	var editor_scene: PackedScene = load(PIXEL_EDITOR_PATH)
	var editor := editor_scene.instantiate()
	editor.target_animation = animation_name
	editor.frame_count = config["frame_count"]
	editor.canvas_width = config["canvas_width"]
	editor.canvas_height = config["canvas_height"]
	editor.source_type = config["source"]

	get_tree().root.add_child(editor)
	queue_free()

func _on_back_pressed() -> void:
	var character_select_scene: PackedScene = load(CHARACTER_SELECT_SCREEN_PATH)
	var character_select := character_select_scene.instantiate()
	get_tree().root.add_child(character_select)
	queue_free()
