extends CharacterBody2D

signal died

@export var speed: float = 100.0
@export var max_health: int = 100
@export var knockback_friction: float = 800.0
@export var character_reward: int = 1
@export var hit_flash_duration: float = 0.4
@export var slow_speed_multiplier: float = 0.5
@export var slow_duration: float = 2.0
@export var freeze_stun_duration: float = 2.0
@export var freeze_bonus_damage_multiplier: float = 1.5
@export var overload_pulse_stun_duration: float = 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hit_box: Area2D = $HitBox
@onready var burn_particles: CPUParticles2D = $BurnParticles
@onready var freeze_particles: CPUParticles2D = $FreezeParticles
@onready var death_sound_player: AudioStreamPlayer2D = $DeathSoundPlayer

var player: Node2D = null
var current_target: Node2D = null
var target_check_timer: float = 0.0
var current_health: int
var is_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var is_flashing: bool = false
var active_statuses: Dictionary = {}
var is_stunned: bool = false
var stun_timer: float = 0.0
var freeze_hit_count: int = 0
var is_slowed: bool = false
var slow_timer: float = 0.0
var is_ice_stunned: bool = false
var ice_stun_timer: float = 0.0
var is_shock_stunned: bool = false
var shock_stun_timer: float = 0.0
var is_conductor: bool = false
var conductor_timer: float = 0.0
var conductor_pulse_timer: float = 0.0
var conductor_radius: float = 180.0
var conductor_pulse_interval: float = 1.0
var conductor_pulse_damage: int = 0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	current_health = max_health
	animated_sprite.play("walk")
	current_target = player

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_process_statuses(delta)

	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false

	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0.0:
			is_slowed = false

	if is_ice_stunned:
		ice_stun_timer -= delta
		if ice_stun_timer <= 0.0:
			is_ice_stunned = false

	if is_shock_stunned:
		shock_stun_timer -= delta
		if shock_stun_timer <= 0.0:
			is_shock_stunned = false

	if is_conductor:
		conductor_timer -= delta
		conductor_pulse_timer -= delta

		if conductor_pulse_timer <= 0.0:
			conductor_pulse_timer = conductor_pulse_interval
			_overload_pulse()

		if conductor_timer <= 0.0:
			is_conductor = false

	if knockback_velocity.length() > 10.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		_update_visual_animation(Vector2.ZERO)
		return

	if is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual_animation(Vector2.ZERO)
		return

	_update_target(delta)

	if current_target == null:
		_update_visual_animation(Vector2.ZERO)
		return

	nav_agent.target_position = current_target.global_position

	if nav_agent.is_navigation_finished():
		_update_visual_animation(Vector2.ZERO)
		return

	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	var direction := (next_path_position - global_position).normalized()

	var current_speed: float = speed * slow_speed_multiplier if is_slowed else speed
	velocity = direction * current_speed
	move_and_slide()

	_update_visual_animation(direction)

func _update_target(delta: float) -> void:
	target_check_timer -= delta

	if target_check_timer > 0.0:
		return

	target_check_timer = 0.4

	if player == null:
		return

	var rocket_node: Node2D = get_tree().get_first_node_in_group("rocket")

	if rocket_node == null:
		current_target = player
		return

	var distance_to_player: float = global_position.distance_to(player.global_position)
	var distance_to_rocket: float = global_position.distance_to(rocket_node.global_position)

	if distance_to_rocket < distance_to_player:
		current_target = rocket_node
	else:
		current_target = player

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	print("Enemy health: ", current_health)

	_flash_red_white()

	if current_health <= 0:
		die()

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force

func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_timer = max(stun_timer, duration)

func apply_pull(target_position: Vector2, force: float) -> void:
	var direction: Vector2 = (target_position - global_position).normalized()
	knockback_velocity = direction * force

func apply_slow(duration: float) -> void:
	is_slowed = true
	slow_timer = max(slow_timer, duration)

func apply_freeze_hit() -> float:
	freeze_hit_count += 1
	var stage: int = ((freeze_hit_count - 1) % 3) + 1

	match stage:
		1:
			apply_slow(slow_duration)
		2:
			apply_stun(freeze_stun_duration)
			is_ice_stunned = true
			ice_stun_timer = freeze_stun_duration
		3:
			return freeze_bonus_damage_multiplier

	return 1.0

func start_overload_conductor(duration: float, pulse_interval: float, radius: float, pulse_damage: int) -> void:
	is_conductor = true
	conductor_timer = duration
	conductor_pulse_timer = pulse_interval
	conductor_radius = radius
	conductor_pulse_interval = pulse_interval
	conductor_pulse_damage = pulse_damage
	_overload_pulse()

func _overload_pulse() -> void:
	apply_stun(overload_pulse_stun_duration)
	take_damage(conductor_pulse_damage)

	var enemies: Array = get_tree().get_nodes_in_group("enemy")

	for enemy_node in enemies:
		if enemy_node == self:
			continue

		if global_position.distance_to(enemy_node.global_position) <= conductor_radius:
			if enemy_node.has_method("apply_stun"):
				enemy_node.apply_stun(overload_pulse_stun_duration)
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(conductor_pulse_damage)

func apply_status(status_name: String, tick_value: float, tick_interval: float, duration: float, status_type: String = "damage") -> void:
	active_statuses[status_name] = {
		"tick_value": tick_value,
		"tick_interval": tick_interval,
		"time_since_last_tick": 0.0,
		"remaining_duration": duration,
		"type": status_type,
	}

func _process_statuses(delta: float) -> void:
	var statuses_to_remove: Array = []

	for status_name in active_statuses.keys():
		var status: Dictionary = active_statuses[status_name]
		status["remaining_duration"] -= delta
		status["time_since_last_tick"] += delta

		if status["time_since_last_tick"] >= status["tick_interval"]:
			status["time_since_last_tick"] = 0.0
			if status["type"] == "stun":
				apply_stun(status["tick_value"])
				if status_name == "shock":
					is_shock_stunned = true
					shock_stun_timer = status["tick_value"]
			else:
				take_damage(int(status["tick_value"]))

		if status["remaining_duration"] <= 0.0:
			statuses_to_remove.append(status_name)

	for status_name in statuses_to_remove:
		active_statuses.erase(status_name)

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO

	hit_box.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	animated_sprite.visible = false

	CurrencyManager.add_characters(character_reward)

	print("Enemy died")
	died.emit()

	death_sound_player.play()
	await death_sound_player.finished
	queue_free()

func update_animation(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite.flip_h = direction.x < 0
		animated_sprite.play("walk_side")
	else:
		if direction.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")

func _update_visual_animation(direction: Vector2) -> void:
	var target_animation: String = "walk"

	if active_statuses.has("burn"):
		target_animation = "burn"
	elif is_ice_stunned:
		target_animation = "ice"
	elif is_shock_stunned:
		target_animation = "shock"
	elif active_statuses.has("shock"):
		target_animation = "thunder"
	elif is_slowed:
		target_animation = "frost"

	if animated_sprite.animation != target_animation:
		animated_sprite.play(target_animation)

	if direction != Vector2.ZERO:
		animated_sprite.flip_h = direction.x < 0

func _flash_red_white() -> void:
	if is_flashing:
		return

	is_flashing = true
	var tween_flash := create_tween()
	var flash_count := 3
	var flash_time: float = hit_flash_duration / (flash_count * 2)

	for i in range(flash_count):
		tween_flash.tween_property(animated_sprite, "modulate", Color(1.0, 0.3, 0.3), flash_time)
		tween_flash.tween_property(animated_sprite, "modulate", Color(1.5, 1.5, 1.5), flash_time)

	tween_flash.tween_property(animated_sprite, "modulate", Color.WHITE, flash_time)

	await tween_flash.finished
	is_flashing = false
