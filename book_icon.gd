extends Control

const GUIDE_BOOK_PATH := "res://guide_book.tscn"

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_open_guide_book()

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + drag_offset
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false

func _open_guide_book() -> void:
	if not ResourceLoader.exists(GUIDE_BOOK_PATH):
		print("Guide book not built yet.")
		return

	var guide_scene: PackedScene = load(GUIDE_BOOK_PATH)
	var guide_book := guide_scene.instantiate()
	get_tree().root.add_child(guide_book)
	guide_book.set_spawn_position(global_position)
