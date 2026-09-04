extends CanvasLayer
signal closed

@export var message_label: Label
@export var ok_button: BaseButton
@export var view_button: BaseButton
@export var fix_button: BaseButton
@export var close_button: BaseButton
@export var title_bar: Control
@export var beep_player: AudioStreamPlayer2D
@export var window: Control

const VIEW_SCREEN_PATH := "res://view_screen.tscn"
const FIX_SCREEN_PATH := "res://fix_screen.tscn"

var target_element: String = ""
var severity: String = "critical"
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if severity == "low":
		var percent_left: float = CorruptionManager.get_durability(target_element)
		message_label.text = "'%s' is degrading (%d%% remaining)." % [target_element, int(percent_left)]
		window.modulate = Color(1.0, 0.95, 0.55)
	else:
		message_label.text = "'%s' is not responding." % target_element
		window.modulate = Color(1.0, 1.0, 1.0)

	ok_button.pressed.connect(_on_ok_pressed)
	view_button.pressed.connect(_on_view_pressed)
	fix_button.pressed.connect(_on_fix_pressed)
	close_button.pressed.connect(_on_close_pressed)
	title_bar.gui_input.connect(_on_title_bar_gui_input)

func _on_ok_pressed() -> void:
	if beep_player.stream:
		beep_player.play()
	else:
		print("Beep sound not assigned yet.")

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()

func _on_view_pressed() -> void:
	if not ResourceLoader.exists(VIEW_SCREEN_PATH):
		print("View screen not built yet.")
		return

	var view_scene: PackedScene = load(VIEW_SCREEN_PATH)
	var view_screen := view_scene.instantiate()
	get_tree().root.add_child(view_screen)

func _on_fix_pressed() -> void:
	if not ResourceLoader.exists(FIX_SCREEN_PATH):
		print("Fix screen not built yet.")
		return

	var fix_scene: PackedScene = load(FIX_SCREEN_PATH)
	var fix_screen := fix_scene.instantiate()
	fix_screen.target_element = target_element
	get_tree().root.add_child(fix_screen)
	queue_free()
	
func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = window.position - get_viewport().get_mouse_position()
		else:
			is_dragging = false

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseMotion:
		window.position = get_viewport().get_mouse_position() + drag_offset
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false
