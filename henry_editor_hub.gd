extends CanvasLayer

const CHARACTER_SELECT_SCREEN_PATH := "res://character_select_screen.tscn"
const PIXEL_EDITOR_PATH := "res://pixel_editor.tscn"

# animation name → frame count
const ANIMATION_FRAME_COUNTS := {
	"walk_down": 4,
	"walk_up": 4,
	"walk_side": 8,
	"idle_down": 1,
	"idle_up": 1,
}

func _ready() -> void:
	CursorManager.use_default_cursor()
	$WalkDownButton.pressed.connect(_open_editor.bind("walk_down"))
	$WalkUpButton.pressed.connect(_open_editor.bind("walk_up"))
	$WalkSideButton.pressed.connect(_open_editor.bind("walk_side"))
	$IdleDownButton.pressed.connect(_open_editor.bind("idle_down"))
	$IdleUpButton.pressed.connect(_open_editor.bind("idle_up"))
	$BackButton.pressed.connect(_on_back_pressed)

func _open_editor(animation_name: String) -> void:
	var editor_scene: PackedScene = load(PIXEL_EDITOR_PATH)
	var editor := editor_scene.instantiate()
	editor.target_animation = animation_name
	editor.frame_count = ANIMATION_FRAME_COUNTS[animation_name]
	get_tree().root.add_child(editor)
	queue_free()

func _on_back_pressed() -> void:
	var character_select_scene: PackedScene = load(CHARACTER_SELECT_SCREEN_PATH)
	var character_select := character_select_scene.instantiate()
	get_tree().root.add_child(character_select)
	queue_free()
