extends Area2D

@onready var damage_timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("rocket"):
		if damage_timer.is_stopped():
			damage_timer.start()
			_deal_damage_to_all()

func _on_body_exited(_body: Node2D) -> void:
	if not monitoring:
		return

	if get_overlapping_bodies().is_empty():
		damage_timer.stop()

func _on_timer_timeout() -> void:
	_deal_damage_to_all()

func _deal_damage_to_all() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(10)
		elif body.is_in_group("rocket"):
			if body.has_method("take_hit"):
				body.take_hit()
