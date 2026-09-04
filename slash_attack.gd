extends Area2D

@export var damage: int = 10
@export var knockback_force: float = 400.0
@export var lightning_chain_count: int = 3
@export var lightning_chain_radius: float = 100.0
@export var lightning_stun_duration: float = 1.0
@export var gravity_pull_force: float = 150.0
@export var life_steal_heal_amount: int = 1
@export var shock_status_tick_interval: float = 3.5
@export var shock_status_duration: float = 10.0
@export var shock_status_stun_duration: float = 1.0
@export var overload_conductor_duration: float = 5.0
@export var overload_pulse_interval: float = 1.0
@export var overload_pulse_radius: float = 180.0
@export var freezeburn_slow_duration: float = 2.0
@export var freezeburn_damage_multiplier: float = 1.25

const STATUS_CONFIG := {
	"burn": {"tick_interval": 1.0, "duration": 5.0, "damage_percent": 0.2},
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var swing_sound_player: AudioStreamPlayer2D = $SwingSoundPlayer

func _ready() -> void:
	_apply_custom_sprites()
	animated_sprite.play("slash")
	swing_sound_player.play()
	body_entered.connect(_on_body_entered)
	await animated_sprite.animation_finished
	queue_free()

func _apply_custom_sprites() -> void:
	var sprite_frames: SpriteFrames = animated_sprite.sprite_frames
	var frame_count: int = sprite_frames.get_frame_count("slash")
	for i in range(frame_count):
		var custom_path := "user://darp_custom/slash_%d.png" % i
		if FileAccess.file_exists(custom_path):
			var img := Image.load_from_file(custom_path)
			var custom_texture := ImageTexture.create_from_image(img)
			sprite_frames.set_frame("slash", i, custom_texture)

func _on_body_entered(body: Node2D) -> void:
	print("Slash hit: ", body.name, " | groups: ", body.get_groups())

	if body.is_in_group("enemy"):
		var total_damage: int = damage + WeaponEffectManager.damage_bonus

		if WeaponEffectManager.has_effect("freeze") and body.has_method("apply_freeze_hit"):
			var freeze_multiplier: float = body.apply_freeze_hit()
			total_damage = int(total_damage * freeze_multiplier)

		if WeaponEffectManager.has_effect("freezeburn"):
			total_damage = int(total_damage * freezeburn_damage_multiplier)
			if body.has_method("apply_slow"):
				body.apply_slow(freezeburn_slow_duration)

		var chain_targets: Array = []
		if WeaponEffectManager.has_effect("shock"):
			chain_targets = _get_lightning_chain_targets(body)
			var hit_count: int = 1 + chain_targets.size()
			total_damage = int(total_damage * _lightning_damage_percent(hit_count))

		body.take_damage(total_damage)
		var knock_direction: Vector2 = (body.global_position - global_position).normalized()
		body.apply_knockback(knock_direction, knockback_force)

		for effect_name in WeaponEffectManager.active_effects:
			if STATUS_CONFIG.has(effect_name):
				var config: Dictionary = STATUS_CONFIG[effect_name]
				var tick_damage: int = int(total_damage * config["damage_percent"])
				body.apply_status(effect_name, tick_damage, config["tick_interval"], config["duration"])

		if WeaponEffectManager.has_effect("shock"):
			_resolve_lightning(body, total_damage, chain_targets)

		if WeaponEffectManager.has_effect("overload") and body.has_method("start_overload_conductor"):
			var pulse_damage: int = int(total_damage * 0.5)
			body.start_overload_conductor(overload_conductor_duration, overload_pulse_interval, overload_pulse_radius, pulse_damage)

		if WeaponEffectManager.has_effect("life_steal"):
			var player_node: Node2D = get_tree().get_first_node_in_group("player")
			if player_node and player_node.has_method("heal"):
				player_node.heal(life_steal_heal_amount)

		if WeaponEffectManager.has_effect("force") and body.has_method("apply_pull"):
			body.apply_pull(global_position, gravity_pull_force)
	elif body.is_in_group("rocket"):
		if body.has_method("take_hit"):
			body.take_hit()

func _get_lightning_chain_targets(primary_target: Node2D) -> Array:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	var targets: Array = []

	for enemy_node in enemies:
		if enemy_node == primary_target or targets.size() >= lightning_chain_count:
			continue

		if primary_target.global_position.distance_to(enemy_node.global_position) <= lightning_chain_radius:
			targets.append(enemy_node)

	return targets

func _lightning_damage_percent(hit_count: int) -> float:
	match hit_count:
		1:
			return 1.0
		2:
			return 0.75
		3:
			return 0.5
		_:
			return 0.25

func _resolve_lightning(primary_target: Node2D, final_damage: int, chain_targets: Array) -> void:
	if primary_target.has_method("apply_status"):
		primary_target.apply_status("shock", shock_status_stun_duration, shock_status_tick_interval, shock_status_duration, "stun")

	for enemy_node in chain_targets:
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(final_damage)
		if enemy_node.has_method("apply_stun"):
			enemy_node.apply_stun(lightning_stun_duration)
