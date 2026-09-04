extends Node

const DOT_CURSOR_PATH := "res://assets/cursor_dot.png"
var dot_cursor_texture: Texture2D

func _ready() -> void:
	if ResourceLoader.exists(DOT_CURSOR_PATH):
		dot_cursor_texture = load(DOT_CURSOR_PATH)

func use_dot_cursor() -> void:
	if dot_cursor_texture:
		Input.set_custom_mouse_cursor(dot_cursor_texture, Input.CURSOR_ARROW, Vector2(8, 8))

func use_default_cursor() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
