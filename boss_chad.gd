extends "res://boss_base.gd"

enum AttackPattern { COMBO, DASH_CHARGE, JUMP_CHARGE, NORMAL_PUNCH }

@export var combo_hit_count: int = 8
@export var combo_punch_interval: float = 0.3
@export var combo_punch_damage: int = 10
@export var combo_move_distance: float = 40.0
@export var combo_punch_range: float = 60.0

@export var chase_speed: float = 240.0
@export var normal_punch_range: float = 60.0
@export var normal_punch_damage: int = 15
@export var punch_windup_duration: float = 1.0
@export var normal_punch_recovery: float = 0.4

@export var dash_windup_time: float = 0.8
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.6
@export var dash_hit_range: float = 50.0
@export var dash_damage: int = 20
@export var dash_carry_duration: float = 0.3
@export var dash_carry_distance: float = 20.0

@export var jump_track_duration: float = 1.0
@export var jump_lock_duration: float = 0.4
@export var jump_hit_range: float = 60.0
@export var jump_damage: int = 20

@export var close_range_distance: float = 80.0

var current_pattern: AttackPattern = AttackPattern.NORMAL_PUNCH
var is_chasing: bool = false

var punches_thrown: int = 0
var punch_timer: float = 0.0

var dash_direction: Vector2 = Vector2.ZERO
var dash_has_hit: bool = false
var dash_base_position: Vector2 = Vector2.ZERO

var is_tracking_jump: bool = false
var jump_target_position: Vector2 = Vector2.ZERO

func _advance_state() -> void:
	match current_state:
		State.IDLE:
			current_pattern = _choose_pattern()
			_enter_state(State.TELEGRAPH)
		State.TELEGRAPH:
			if current_pattern == AttackPattern.JUMP_CHARGE and is_tracking_jump:
				is_tracking_jump = false
				jump_target_position = global_position
				state_timer = jump_lock_duration
				_update_debug_visual()
			else:
				_enter_state(State.ATTACK)
		State.ATTACK:
			_choose_next_after_attack()
		State.VULNERABLE:
			_enter_state(State.IDLE)

func _enter_state(new_state: State) -> void:
	current_state = new_state

	match current_state:
		State.IDLE:
			state_timer = idle_duration
		State.TELEGRAPH:
			print("Pattern chosen: ", AttackPattern.keys()[current_pattern], " (HP: ", current_health, "/", max_health, ")")
			if current_pattern == AttackPattern.NORMAL_PUNCH:
				is_chasing = true
				state_timer = 999.0
			elif current_pattern == AttackPattern.JUMP_CHARGE:
				is_tracking_jump = true
				state_timer = jump_track_duration
				if collision_shape:
					collision_shape.set_deferred("disabled", true)
			else:
				state_timer = _telegraph_duration_for_pattern()

			if current_pattern == AttackPattern.DASH_CHARGE:
				dash_base_position = global_position
				_play_dash_shake()
		State.ATTACK:
			state_timer = _attack_duration_for_pattern()
			if current_pattern == AttackPattern.COMBO:
				punches_thrown = 0
				punch_timer = 0.0
			elif current_pattern == AttackPattern.NORMAL_PUNCH:
				_throw_normal_punch()
			elif current_pattern == AttackPattern.DASH_CHARGE:
				dash_direction = (player.global_position - global_position).normalized() if player else Vector2.ZERO
				dash_has_hit = false
			elif current_pattern == AttackPattern.JUMP_CHARGE:
				if collision_shape:
					collision_shape.set_deferred("disabled", false)
				global_position = jump_target_position
				_resolve_jump_landing()
		State.VULNERABLE:
			state_timer = vulnerable_duration

	_update_debug_visual()

func _choose_pattern() -> AttackPattern:
	var health_ratio: float = float(current_health) / float(max_health)

	if randf() < health_ratio:
		return AttackPattern.DASH_CHARGE if randi() % 2 == 0 else AttackPattern.JUMP_CHARGE

	return AttackPattern.NORMAL_PUNCH

func _choose_next_after_attack() -> void:
	var distance: float = global_position.distance_to(player.global_position) if player else 999.0
	var is_close: bool = distance <= close_range_distance

	var combo_chance: float = 60.0 if is_close else 15.0
	var punch_chance: float = 25.0 if is_close else 35.0

	var roll: float = randf() * 100.0

	if roll < combo_chance:
		current_pattern = AttackPattern.COMBO
		_enter_state(State.ATTACK)
	elif roll < combo_chance + punch_chance:
		current_pattern = AttackPattern.NORMAL_PUNCH
		_enter_state(State.TELEGRAPH)
	else:
		_enter_state(State.VULNERABLE)

func _telegraph_duration_for_pattern() -> float:
	match current_pattern:
		AttackPattern.DASH_CHARGE:
			return dash_windup_time
		_:
			return telegraph_duration

func _attack_duration_for_pattern() -> float:
	match current_pattern:
		AttackPattern.COMBO:
			return combo_hit_count * combo_punch_interval
		AttackPattern.NORMAL_PUNCH:
			return normal_punch_recovery
		AttackPattern.DASH_CHARGE:
			return dash_duration
		_:
			return attack_duration

func _process_current_state(delta: float) -> void:
	if current_state == State.TELEGRAPH and current_pattern == AttackPattern.NORMAL_PUNCH and is_chasing:
		_process_chase(delta)
	elif current_state == State.TELEGRAPH and current_pattern == AttackPattern.JUMP_CHARGE and is_tracking_jump:
		if player:
			global_position = player.global_position
	elif current_state == State.ATTACK and current_pattern == AttackPattern.COMBO:
		_process_combo(delta)
	elif current_state == State.ATTACK and current_pattern == AttackPattern.DASH_CHARGE:
		_process_dash(delta)

func _process_chase(delta: float) -> void:
	if not player:
		return

	var distance: float = global_position.distance_to(player.global_position)

	if distance <= normal_punch_range:
		is_chasing = false
		state_timer = punch_windup_duration
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()
	global_position += direction * chase_speed * delta

func _throw_normal_punch() -> void:
	print("Normal punch thrown!")
	if player and global_position.distance_to(player.global_position) <= normal_punch_range:
		player.take_damage(normal_punch_damage, global_position)

func _process_combo(delta: float) -> void:
	punch_timer -= delta

	if punch_timer <= 0.0 and punches_thrown < combo_hit_count:
		_throw_punch()
		punches_thrown += 1
		punch_timer = combo_punch_interval

func _throw_punch() -> void:
	if not player:
		return

	var direction: Vector2 = _get_4way_direction_to_player()
	global_position += direction * combo_move_distance

	print("Punch #", punches_thrown + 1, " direction: ", direction)

	if global_position.distance_to(player.global_position) <= combo_punch_range:
		player.take_damage(combo_punch_damage, global_position)

func _get_4way_direction_to_player() -> Vector2:
	var diff: Vector2 = player.global_position - global_position

	if abs(diff.x) > abs(diff.y):
		return Vector2(sign(diff.x), 0)

	return Vector2(0, sign(diff.y))

func _play_dash_shake() -> void:
	var shake_tween := create_tween()
	var shake_count := 6
	var shake_time: float = dash_windup_time / (shake_count * 2)

	for i in range(shake_count):
		shake_tween.tween_property(self, "global_position", dash_base_position + Vector2(8, 0), shake_time)
		shake_tween.tween_property(self, "global_position", dash_base_position - Vector2(8, 0), shake_time)

	shake_tween.tween_property(self, "global_position", dash_base_position, shake_time)

func _process_dash(delta: float) -> void:
	if dash_has_hit or not player:
		return

	global_position += dash_direction * dash_speed * delta

	if global_position.distance_to(player.global_position) <= dash_hit_range:
		dash_has_hit = true
		_resolve_dash_hit()

func _resolve_dash_hit() -> void:
	is_locked_in_action = true
	player.lock_movement()

	var carry_offset: Vector2 = dash_direction * dash_carry_distance
	var carry_tween := create_tween()
	carry_tween.tween_property(self, "global_position", global_position + carry_offset, dash_carry_duration)
	carry_tween.parallel().tween_property(player, "global_position", player.global_position + carry_offset, dash_carry_duration)

	await carry_tween.finished

	player.take_damage(dash_damage, global_position)
	player.apply_deformation("stretched")
	player.unlock_movement()

	is_locked_in_action = false

func _resolve_jump_landing() -> void:
	print("Slam landed!")
	if player and global_position.distance_to(player.global_position) <= jump_hit_range:
		player.take_damage(jump_damage, global_position)
		player.apply_deformation("flattened")

func _update_debug_visual() -> void:
	if not debug_color_rect:
		return

	if current_state == State.VULNERABLE:
		debug_color_rect.color = Color(0.2, 0.8, 0.3)
	elif current_state == State.IDLE:
		debug_color_rect.color = Color(0.5, 0.5, 0.5)
	elif current_pattern == AttackPattern.COMBO:
		debug_color_rect.color = Color(1.0, 0.55, 0.1)
	elif current_pattern == AttackPattern.NORMAL_PUNCH:
		debug_color_rect.color = Color(0.9, 0.2, 0.2)
	elif current_pattern == AttackPattern.DASH_CHARGE:
		debug_color_rect.color = Color(0.6, 0.2, 0.9)
	elif current_pattern == AttackPattern.JUMP_CHARGE:
		if is_tracking_jump:
			debug_color_rect.color = Color(0.4, 0.75, 1.0)
		else:
			debug_color_rect.color = Color(0.1, 0.15, 0.75)
	else:
		debug_color_rect.color = Color(0.5, 0.5, 0.5)
