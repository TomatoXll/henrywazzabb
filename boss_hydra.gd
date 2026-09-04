extends "res://boss_base.gd"

enum Head3Skill { METEOR, POISON_POOL, TAIL }
enum Head1Attack { NORMAL, FIRE_BREATH }
enum Head2Attack { CIRCULAR_BEAM, LOCKED_BEAM }

@export var head1_max_hp: int = 200
@export var head2_max_hp: int = 200
@export var head3_max_hp: int = 200

@export var close_range_distance: float = 100.0

@export var head3_skill_interval_min: float = 8.0
@export var head3_skill_interval_max: float = 12.0

@export var head1_melee_range: float = 70.0
@export var head1_normal_damage: int = 15

@export var fire_breath_range: float = 180.0
@export var fire_breath_duration: float = 0.8
@export var fire_breath_damage: int = 20
@export var fire_breath_angle_tolerance: float = 35.0

@export var head2_range: float = 200.0
@export var circular_beam_damage: int = 10
@export var circular_beam_rotation_duration: float = 2.5
@export var circular_beam_tick_interval: float = 0.3
@export var circular_beam_angle_tolerance: float = 12.0

@export var locked_beam_telegraph_duration: float = 0.5
@export var locked_beam_fire_duration: float = 0.3
@export var locked_beam_damage: int = 25
@export var locked_beam_angle_tolerance: float = 15.0

@export var meteor_telegraph_duration: float = 1.2
@export var meteor_radius: float = 60.0
@export var meteor_damage: int = 20

@export var poison_pool_count: int = 3
@export var poison_pool_scatter_radius: float = 120.0

@export var tail_spin_duration: float = 1.0
@export var tail_range: float = 90.0
@export var tail_damage: int = 15
@export var tail_angle_tolerance: float = 25.0

@onready var fire_breath_visual: ColorRect = get_node_or_null("FireBreathVisual")
@onready var circular_beam_visual: ColorRect = get_node_or_null("CircularBeamVisual")
@onready var locked_beam_visual: ColorRect = get_node_or_null("LockedBeamVisual")
@onready var meteor_visual: ColorRect = get_node_or_null("MeteorVisual")
@onready var meteor_warning_visual: ColorRect = get_node_or_null("MeteorWarningVisual")
@onready var tail_visual: ColorRect = get_node_or_null("TailVisual")

const PoisonPoolScene := preload("res://poison_pool.tscn")

var head_hp: Dictionary = {}
var head_alive: Dictionary = {}

var active_head_ab: String = ""
var active_head_3: bool = false

var head3_timer: float = 0.0

var current_head1_attack: Head1Attack = Head1Attack.NORMAL
var fire_breath_direction: Vector2 = Vector2.ZERO

var current_head2_attack: Head2Attack = Head2Attack.CIRCULAR_BEAM
var circular_beam_angle: float = 0.0
var circular_beam_tick_timer: float = 0.0
var locked_beam_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	head_hp = {"head1": head1_max_hp, "head2": head2_max_hp, "head3": head3_max_hp}
	head_alive = {"head1": true, "head2": true, "head3": true}
	max_health = head1_max_hp + head2_max_hp + head3_max_hp

	super._ready()

	head3_timer = randf_range(head3_skill_interval_min, head3_skill_interval_max)

func _enter_state(new_state: State) -> void:
	current_state = new_state

	match current_state:
		State.IDLE:
			state_timer = idle_duration
		State.TELEGRAPH:
			active_head_ab = _choose_head_ab()
			print("Head A/B active: ", active_head_ab)

			if active_head_ab == "head1":
				current_head1_attack = Head1Attack.values()[randi() % Head1Attack.size()]
				print("Head1 attack: ", Head1Attack.keys()[current_head1_attack])
				state_timer = telegraph_duration
			elif active_head_ab == "head2":
				current_head2_attack = Head2Attack.values()[randi() % Head2Attack.size()]
				print("Head2 attack: ", Head2Attack.keys()[current_head2_attack])
				if current_head2_attack == Head2Attack.LOCKED_BEAM:
					_start_locked_beam_telegraph()
					state_timer = locked_beam_telegraph_duration
				else:
					state_timer = telegraph_duration
			else:
				state_timer = telegraph_duration
		State.ATTACK:
			state_timer = _attack_duration_for_head_ab()
			if active_head_ab == "head1":
				_resolve_head1_attack()
			elif active_head_ab == "head2":
				_start_head2_attack()
		State.VULNERABLE:
			state_timer = vulnerable_duration
			if circular_beam_visual:
				circular_beam_visual.visible = false
			if locked_beam_visual:
				locked_beam_visual.visible = false

	_update_debug_visual()

func _attack_duration_for_head_ab() -> float:
	if active_head_ab == "head1" and current_head1_attack == Head1Attack.FIRE_BREATH:
		return fire_breath_duration
	if active_head_ab == "head2":
		if current_head2_attack == Head2Attack.CIRCULAR_BEAM:
			return circular_beam_rotation_duration
		return locked_beam_fire_duration
	return attack_duration

func _choose_head_ab() -> String:
	if not player:
		return ""

	var distance: float = global_position.distance_to(player.global_position)
	var candidates: Array = []

	if head_alive.get("head1", false):
		candidates.append("head1")
	if head_alive.get("head2", false):
		candidates.append("head2")

	if candidates.is_empty():
		return ""

	if distance <= close_range_distance and "head1" in candidates:
		return "head1"
	elif distance > close_range_distance and "head2" in candidates:
		return "head2"

	return candidates[randi() % candidates.size()]

func _resolve_head1_attack() -> void:
	if current_head1_attack == Head1Attack.NORMAL:
		_play_head1_normal_attack()
	else:
		_play_fire_breath()

func _play_head1_normal_attack() -> void:
	if not debug_color_rect or not player:
		return

	var base_pos: Vector2 = debug_color_rect.position
	var direction: Vector2 = (player.global_position - global_position).normalized()

	var shake_tween := create_tween()
	shake_tween.tween_property(debug_color_rect, "position", base_pos + direction * 15, 0.1)
	shake_tween.tween_property(debug_color_rect, "position", base_pos, 0.15)

	if global_position.distance_to(player.global_position) <= head1_melee_range:
		player.take_damage(head1_normal_damage, global_position)

func _play_fire_breath() -> void:
	if not fire_breath_visual or not player:
		return

	fire_breath_direction = (player.global_position - global_position).normalized()
	fire_breath_visual.rotation = fire_breath_direction.angle()
	fire_breath_visual.size.x = 0.0
	fire_breath_visual.visible = true

	var stretch_tween := create_tween()
	stretch_tween.tween_property(fire_breath_visual, "size:x", fire_breath_range, fire_breath_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await stretch_tween.finished

	fire_breath_visual.visible = false

	if player:
		var to_player: Vector2 = player.global_position - global_position
		var angle_diff: float = rad_to_deg(abs(fire_breath_direction.angle_to(to_player.normalized())))

		if to_player.length() <= fire_breath_range and angle_diff <= fire_breath_angle_tolerance:
			player.take_damage(fire_breath_damage, global_position)

func _start_locked_beam_telegraph() -> void:
	if not locked_beam_visual or not player:
		return

	locked_beam_direction = (player.global_position - global_position).normalized()
	locked_beam_visual.rotation = locked_beam_direction.angle()
	locked_beam_visual.size = Vector2(head2_range, 2)
	locked_beam_visual.color = Color(1.0, 0.2, 0.2, 0.5)
	locked_beam_visual.visible = true

func _start_head2_attack() -> void:
	if current_head2_attack == Head2Attack.CIRCULAR_BEAM:
		_start_circular_beam()
	else:
		_fire_locked_beam()

func _start_circular_beam() -> void:
	if not circular_beam_visual:
		return

	circular_beam_angle = 0.0
	circular_beam_tick_timer = 0.0
	circular_beam_visual.rotation = 0.0
	circular_beam_visual.visible = true

func _fire_locked_beam() -> void:
	if not locked_beam_visual:
		return

	locked_beam_visual.size = Vector2(head2_range, 6)
	locked_beam_visual.color = Color(1.0, 0.3, 0.3, 1.0)

	if player:
		var to_player: Vector2 = player.global_position - global_position
		var angle_diff: float = rad_to_deg(abs(locked_beam_direction.angle_to(to_player.normalized())))

		if to_player.length() <= head2_range and angle_diff <= locked_beam_angle_tolerance:
			player.take_damage(locked_beam_damage, global_position)

func _process_circular_beam(delta: float) -> void:
	if not circular_beam_visual or not player:
		return

	var progress: float = 1.0 - (state_timer / circular_beam_rotation_duration)
	circular_beam_angle = progress * TAU
	circular_beam_visual.rotation = circular_beam_angle

	circular_beam_tick_timer -= delta
	if circular_beam_tick_timer <= 0.0:
		circular_beam_tick_timer = circular_beam_tick_interval

		var to_player: Vector2 = player.global_position - global_position
		var beam_dir: Vector2 = Vector2.RIGHT.rotated(circular_beam_angle)
		var angle_diff: float = rad_to_deg(abs(beam_dir.angle_to(to_player.normalized())))

		if to_player.length() <= head2_range and angle_diff <= circular_beam_angle_tolerance:
			player.take_damage(circular_beam_damage, global_position)

func _process_current_state(delta: float) -> void:
	_process_head3(delta)

	if current_state == State.ATTACK and active_head_ab == "head2" and current_head2_attack == Head2Attack.CIRCULAR_BEAM:
		_process_circular_beam(delta)

func _process_head3(delta: float) -> void:
	if not head_alive.get("head3", false) or active_head_3:
		return

	head3_timer -= delta

	if head3_timer <= 0.0:
		_trigger_head3_skill()
		head3_timer = randf_range(head3_skill_interval_min, head3_skill_interval_max)

func _trigger_head3_skill() -> void:
	var skill: Head3Skill = Head3Skill.values()[randi() % Head3Skill.size()]
	print("Head 3 skill: ", Head3Skill.keys()[skill])

	active_head_3 = true
	_update_debug_visual()

	match skill:
		Head3Skill.METEOR:
			await _play_meteor()
		Head3Skill.POISON_POOL:
			_play_poison_pool()
		Head3Skill.TAIL:
			await _play_tail()

	active_head_3 = false
	_update_debug_visual()

func _play_meteor() -> void:
	if not player:
		return

	var telegraph_time: float = meteor_telegraph_duration if meteor_telegraph_duration > 0.0 else 1.2
	var target_position: Vector2 = player.global_position

	if meteor_warning_visual:
		meteor_warning_visual.global_position = target_position
		meteor_warning_visual.visible = true

	if meteor_visual:
		meteor_visual.global_position = target_position
		meteor_visual.visible = true
		meteor_visual.scale = Vector2(3.0, 3.0)

		var meteor_tween := create_tween()
		meteor_tween.set_parallel(true)
		meteor_tween.tween_property(meteor_visual, "scale", Vector2(1.0, 1.0), meteor_telegraph_duration)
		meteor_tween.tween_property(meteor_visual, "rotation", TAU * 3, meteor_telegraph_duration)

	await get_tree().create_timer(telegraph_time).timeout

	if meteor_warning_visual:
		meteor_warning_visual.visible = false
	if meteor_visual:
		meteor_visual.visible = false

	if player and player.global_position.distance_to(target_position) <= meteor_radius:
		player.take_damage(meteor_damage, target_position)
		player.apply_deformation("flattened")

func _play_poison_pool() -> void:
	if not player:
		return

	for i in range(poison_pool_count):
		var offset: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * randf_range(20.0, poison_pool_scatter_radius)
		var spawn_position: Vector2 = player.global_position + offset

		var pool_instance: Node2D = PoisonPoolScene.instantiate()
		get_tree().root.add_child(pool_instance)
		pool_instance.global_position = spawn_position

func _play_tail() -> void:
	if not tail_visual:
		return

	tail_visual.rotation = 0.0
	tail_visual.visible = true

	var elapsed: float = 0.0
	var tick_timer: float = 0.0

	while elapsed < tail_spin_duration:
		await get_tree().process_frame
		var delta: float = get_process_delta_time()
		elapsed += delta

		var progress: float = elapsed / tail_spin_duration
		var angle: float = progress * TAU
		tail_visual.rotation = angle

		tick_timer -= delta
		if tick_timer <= 0.0 and player:
			tick_timer = 0.2
			var to_player: Vector2 = player.global_position - global_position
			var beam_dir: Vector2 = Vector2.RIGHT.rotated(angle)
			var angle_diff: float = rad_to_deg(abs(beam_dir.angle_to(to_player.normalized())))

			if to_player.length() <= tail_range and angle_diff <= tail_angle_tolerance:
				player.take_damage(tail_damage, global_position)
				player.apply_deformation("stretched")

	tail_visual.visible = false

func take_damage(amount: int) -> void:
	if is_dead:
		return

	var final_amount: int = amount
	if current_state == State.VULNERABLE:
		final_amount = int(amount * vulnerable_damage_multiplier)

	var targets: Array = []
	if active_head_ab != "" and head_alive.get(active_head_ab, false):
		targets.append(active_head_ab)
	if active_head_3 and head_alive.get("head3", false):
		targets.append("head3")

	if targets.is_empty():
		return

	var damage_per_target: int = final_amount / targets.size()

	for head_name in targets:
		_damage_head(head_name, damage_per_target)

	current_health = head_hp["head1"] + head_hp["head2"] + head_hp["head3"]
	BossHud.update_health(current_health)

	print("HP -> head1: %d | head2: %d | head3: %d" % [head_hp["head1"], head_hp["head2"], head_hp["head3"]])

	if current_health <= 0:
		die()

func _damage_head(head_name: String, amount: int) -> void:
	if not head_alive.get(head_name, false):
		return

	head_hp[head_name] -= amount

	if head_hp[head_name] <= 0:
		head_hp[head_name] = 0
		head_alive[head_name] = false
		print(head_name, " has died!")

func _update_debug_visual() -> void:
	if not debug_color_rect:
		return

	if active_head_ab == "head1":
		debug_color_rect.color = Color(0.9, 0.2, 0.2)
	elif active_head_ab == "head2":
		debug_color_rect.color = Color(0.2, 0.8, 0.3)
	elif active_head_3:
		debug_color_rect.color = Color(1.0, 0.9, 0.2)
	else:
		debug_color_rect.color = Color(0.5, 0.5, 0.5)
