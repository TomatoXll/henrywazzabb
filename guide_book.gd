extends Control

@export var cover_button: TextureButton
@export var page_view: Control
@export var pages: Array[Control] = []
@export var left_click_zone: BaseButton
@export var right_click_zone: BaseButton

var current_page: int = 0

func _ready() -> void:
	page_view.visible = false
	cover_button.pressed.connect(_on_cover_pressed)
	left_click_zone.pressed.connect(_on_left_pressed)
	right_click_zone.pressed.connect(_on_right_pressed)

func _input(event: InputEvent) -> void:
	if not page_view.visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_close_book()

func _on_cover_pressed() -> void:
	cover_button.visible = false
	page_view.visible = true
	current_page = 0
	_update_page()

func _close_book() -> void:
	page_view.visible = false
	cover_button.visible = true

func _on_left_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_update_page()

func _on_right_pressed() -> void:
	if current_page < pages.size() - 1:
		current_page += 1
		_update_page()

func _update_page() -> void:
	for i in range(pages.size()):
		pages[i].visible = (i == current_page)
