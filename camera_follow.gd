extends Camera2D

@export var max_offset: float = 150.0
@export var follow_strength: float = 0.5

var shake_amount: float = 0.0
var shake_decay: float = 5.0

func _physics_process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var player_pos: Vector2 = get_parent().global_position

	var direction: Vector2 = mouse_pos - player_pos
	var target_offset: Vector2 = direction * follow_strength
	target_offset = target_offset.limit_length(max_offset)

	if shake_amount > 0.0:
		var shake_vector := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amount
		target_offset += shake_vector
		shake_amount = max(shake_amount - shake_decay * delta, 0.0)

	offset = target_offset

func trigger_shake(amount: float) -> void:
	shake_amount = amount
