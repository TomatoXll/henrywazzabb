extends CanvasLayer

@onready var container: Control = $Container
@onready var health_bar: ProgressBar = $Container/HealthBar
@onready var name_label: Label = $Container/NameLabel

@export var shake_amount: float = 6.0
@export var shake_duration: float = 0.15
@export var drain_duration: float = 0.4

var base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	base_position = container.position

func show_boss_health(max_hp: int, boss_name: String) -> void:
	health_bar.max_value = max_hp
	health_bar.value = max_hp
	name_label.text = boss_name
	visible = true

func update_health(current_hp: int) -> void:
	_shake()
	_drain_to(current_hp)

func hide_boss_health() -> void:
	visible = false

func _shake() -> void:
	var shake_tween := create_tween()
	shake_tween.tween_property(container, "position", base_position + Vector2(shake_amount, 0), shake_duration / 4)
	shake_tween.tween_property(container, "position", base_position - Vector2(shake_amount, 0), shake_duration / 2)
	shake_tween.tween_property(container, "position", base_position, shake_duration / 4)

func _drain_to(target_value: int) -> void:
	var drain_tween := create_tween()
	drain_tween.tween_property(health_bar, "value", target_value, drain_duration)
