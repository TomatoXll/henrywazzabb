extends Node2D

@export var lifetime: float = 4.0
@export var tick_interval: float = 1.0
@export var damage_per_tick: int = 8
@export var radius: float = 40.0

@onready var visual: ColorRect = $Visual

var player: Node2D = null
var tick_timer: float = 0.0
var life_timer: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	life_timer = lifetime
	tick_timer = tick_interval

	visual.set_anchors_preset(Control.PRESET_TOP_LEFT)
	visual.position = -visual.size / 2.0
	visual.pivot_offset = visual.size / 2.0
	visual.scale = Vector2(1.1, 1.1)

	var squash_tween := create_tween()
	squash_tween.tween_property(visual, "scale", Vector2(1.3, 0.55), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	life_timer -= delta
	if life_timer <= 0.0:
		queue_free()
		return

	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = tick_interval
		if player and global_position.distance_to(player.global_position) <= radius:
			player.take_damage(damage_per_tick, global_position)
