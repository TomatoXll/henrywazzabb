extends CanvasLayer

@export var code_text_edit: TextEdit
@export var compile_button: BaseButton
@export var back_button: BaseButton
@export var output_label: Label
@export var title_label: Label

const RESPAWN_SCREEN_PATH := "res://respawn_screen.tscn"
const JSFixParser = preload("res://js_fix_parser.gd")

var target_element: String = ""
var severity: String = "critical"

func _ready() -> void:
	if title_label:
		title_label.text = "FIX: %s" % target_element.capitalize()

	var display_lines: Array[String] = JSFixParser.get_display_lines(target_element, severity)
	code_text_edit.text = "\n".join(display_lines)

	compile_button.pressed.connect(_on_compile_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_compile_pressed() -> void:
	var code_text: String = code_text_edit.text
	var result: Dictionary = JSFixParser.parse_mock(code_text, target_element)

	if result["is_fully_valid"]:
		CorruptionManager.fix_element(target_element)
		output_label.text = "Compiled successfully.\n'%s' has been repaired." % target_element
	else:
		var error_text := "Compile failed:\n"
		for error in result["errors"]:
			error_text += "  Line %d: %s\n" % [error["line"], error["message"]]
		output_label.text = error_text

func _on_back_pressed() -> void:
	get_tree().paused = false
	var respawn_scene: PackedScene = load(RESPAWN_SCREEN_PATH)
	var respawn_screen := respawn_scene.instantiate()
	get_tree().root.add_child(respawn_screen)
	queue_free()
