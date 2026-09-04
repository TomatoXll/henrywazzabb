extends Node2D

@export var bar_width: float = 40.0
@export var bar_height: float = 5.0
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var fill_color: Color = Color(0.9, 0.8, 0.1)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not HenryAbilityManager.is_ability_unlocked:
		return

	var ratio: float = HenryAbilityManager.current_stamina / HenryAbilityManager.max_stamina
	ratio = clamp(ratio, 0.0, 1.0)

	var bar_position := Vector2(-bar_width / 2.0, 0.0)

	draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), background_color)
	draw_rect(Rect2(bar_position, Vector2(bar_width * ratio, bar_height)), fill_color)
