extends Area2D

@export var follow_speed: float = 12.0
@export var max_tilt_degrees: float = 15.0
@export var tilt_sensitivity: float = 0.05
@export var cartridge_type: String = "new_game"
@export var console_path: NodePath

var is_dragging: bool = false
var is_inserted: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_rotation: float = 0.0
var console_node: Node = null

func _ready() -> void:
	input_event.connect(_on_input_event)
	original_position = position
	original_rotation = rotation
	previous_position = position
	console_node = get_node(console_path)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_inserted:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag()
			else:
				stop_drag()

func start_drag() -> void:
	is_dragging = true
	drag_offset = position - get_global_mouse_position()

func stop_drag() -> void:
	is_dragging = false

	var success: bool = console_node.try_insert(self)
	if success:
		play_insert_animation()
	else:
		play_return_animation()

func play_insert_animation() -> void:
	is_inserted = true
	var target: Vector2 = console_node.get_insert_position()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)

	await tween.finished
	console_node.notify_inserted(cartridge_type)

func play_return_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", original_position, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", original_rotation, 0.4)
func reset_to_tray() -> void:
	is_inserted = false

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(self, "position", original_position, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", original_rotation, 0.4)

func _process(delta: float) -> void:
	if not is_dragging:
		return

	var target_position: Vector2 = get_global_mouse_position() + drag_offset
	position = position.lerp(target_position, follow_speed * delta)

	var velocity: Vector2 = (position - previous_position) / delta
	var target_tilt: float = clamp(velocity.x * tilt_sensitivity, -max_tilt_degrees, max_tilt_degrees)
	rotation_degrees = lerp(rotation_degrees, target_tilt, 8.0 * delta)

	previous_position = position
