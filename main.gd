extends Node2D

func _ready() -> void:
	var cursor_texture: Texture2D = preload("res://assets/curser.png")
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, Vector2(8, 8))
