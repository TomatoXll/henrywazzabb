extends CharacterBody2D

@export var speed: float = 200.0
@export var max_health: int = 100
@export var slash_attack_scene: PackedScene
@export var attack_cooldown: float = 0.5
@export var respawn_screen_scene: PackedScene
@export var dodge_distance: float = 150.0
@export var dodge_duration: float = 0.3
@export var hit_knockback_distance: float = 30.0
@export var hit_flash_duration: float = 0.4
@export var camera_shake_amount: float = 6.0
@export var stretch_scale: Vector2 = Vector2(0.6, 1.6)
@export var flatten_scale: Vector2 = Vector2(1.6, 0.6)
@export var fall_damage_percent: float = 0.08

var is_flashing: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer

const CUSTOM_ANIMATION_FRAME_COUNTS := {
	"walk_down": 4,
	"walk_up": 4,
	"walk_side": 8,
	"idle_down": 1,
	"idle_up": 1,
	"attack": 6,
}

var base_speed: float = 0.0
var base_attack_cooldown: float = 0.0
var last_direction: String = "down"
var last_flip: bool = false
var current_health: int
var is_dead: bool = false
var can_attack: bool = true
var is_attacking: bool = false
var is_dodging: bool = false
var movement_locked: bool = false

func _ready() -> void:
	current_health = max_health
	_apply_custom_sprites()
	base_speed = speed
	base_attack_cooldown = attack_cooldown
	speed = base_speed * (1.0 + HenryStatManager.speed_bonus_percent / 100.0)
	CorruptionManager.game_over_triggered.connect(die)
	RocketSystem.height_reached_zero.connect(die)
	_check_respawn_corruption_on_load()
	_update_deformation_visuals()

func _apply_custom_sprites() -> void:
	var sprite_frames: SpriteFrames = animated_sprite.sprite_frames

	for animation_name in CUSTOM_ANIMATION_FRAME_COUNTS.keys():
		var frame_count: int = CUSTOM_ANIMATION_FRAME_COUNTS[animation_name]

		for i in range(frame_count):
			var custom_path := "user://henry_custom/%s_%d.png" % [animation_name, i]

			if FileAccess.file_exists(custom_path):
				var img := Image.load_from_file(custom_path)
				var custom_texture := ImageTexture.create_from_image(img)
				sprite_frames.set_frame(animation_name, i, custom_texture)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if movement_locked:
		return

	_handle_ability_input()
	HenryAbilityManager.process_tick(delta)

	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()

	var current_speed: float = speed
	if HenryAbilityManager.is_running:
		current_speed = speed * 1.5

	velocity = input_direction * current_speed
	move_and_slide()

	if not is_attacking:
		update_animation(input_direction)

	_update_footstep_sound(input_direction)
func _update_footstep_sound(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if not footstep_player.playing:
			footstep_player.play()
	else:
		if footstep_player.playing:
			footstep_player.stop()
	#_check_fall()

func _handle_ability_input() -> void:
	if not HenryAbilityManager.is_ability_unlocked:
		return

	if Input.is_key_pressed(KEY_SHIFT):
		if not HenryAbilityManager.is_running:
			HenryAbilityManager.try_start_run()
	else:
		HenryAbilityManager.stop_run()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_dead or not HenryAbilityManager.is_ability_unlocked:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if HenryAbilityManager.try_dodge():
			perform_dodge()

func perform_dodge() -> void:
	if is_dodging:
		return

	is_dodging = true
	is_attacking = true

	var dodge_direction: Vector2 = velocity.normalized()
	if dodge_direction == Vector2.ZERO:
		dodge_direction = Vector2(1, 0) if not last_flip else Vector2(-1, 0)
		if last_direction == "up":
			dodge_direction = Vector2(0, -1)
		elif last_direction == "down":
			dodge_direction = Vector2(0, 1)

	animated_sprite.play("dodge")

	var tween := create_tween()
	tween.tween_property(self, "global_position", global_position + dodge_direction * dodge_distance, dodge_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await animated_sprite.animation_finished

	is_dodging = false
	is_attacking = false

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			apply_deformation("stretched")
		elif event.keycode == KEY_2:
			apply_deformation("flattened")

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if can_attack:
				perform_attack()

func perform_attack() -> void:
	can_attack = false
	is_attacking = true

	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = (mouse_pos - global_position).normalized()

	animated_sprite.flip_h = direction.x < 0
	animated_sprite.play("attack")

	var slash := slash_attack_scene.instantiate()
	get_parent().add_child(slash)
	slash.global_position = global_position
	slash.rotation = direction.angle()

	await animated_sprite.animation_finished
	is_attacking = false

	var effective_cooldown: float = base_attack_cooldown * (1.0 - HenryStatManager.attack_speed_bonus_percent / 100.0)
	await get_tree().create_timer(effective_cooldown).timeout
	can_attack = true

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	if randf() * 100.0 < HenryStatManager.dexterity_bonus_percent:
		print("Dodged!")
		return

	current_health -= amount
	print("Player health: ", current_health)

	_apply_hit_feedback(source_position)
	CorruptionManager.register_hit()

	if current_health <= 0:
		die()

func _apply_hit_feedback(source_position: Vector2) -> void:
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera and camera.has_method("trigger_shake"):
		camera.trigger_shake(camera_shake_amount)

	if source_position != Vector2.ZERO:
		var knockback_direction: Vector2 = (global_position - source_position).normalized()
		var tween_move := create_tween()
		tween_move.tween_property(self, "global_position", global_position + knockback_direction * hit_knockback_distance, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_flash_red_white()

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

func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	print("you die")

	var respawn_screen := respawn_screen_scene.instantiate()
	get_tree().root.add_child(respawn_screen)

	get_tree().paused = true

func _check_respawn_corruption_on_load() -> void:
	if not CorruptionManager.is_element_broken("respawn"):
		return

	var warning_scene: PackedScene = load("res://warning_screen.tscn")
	var warning_screen := warning_scene.instantiate()
	warning_screen.target_element = "respawn"
	get_tree().root.add_child.call_deferred(warning_screen)
	get_tree().paused = true

func apply_deformation(deformation_type: String) -> void:
	PlayerStatus.apply_deformation(deformation_type)
	_update_deformation_visuals()

func _update_deformation_visuals() -> void:
	match PlayerStatus.deformation_state:
		"stretched":
			scale = stretch_scale
		"flattened":
			scale = flatten_scale
		_:
			scale = Vector2.ONE

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animated_sprite.flip_h = last_flip
		animated_sprite.play("idle_" + last_direction)
		return

	if abs(direction.x) > abs(direction.y):
		last_direction = "side"
		last_flip = direction.x < 0
		animated_sprite.flip_h = last_flip
		animated_sprite.play("walk_side")
	else:
		last_direction = "down" if direction.y > 0 else "up"
		last_flip = false
		animated_sprite.flip_h = false
		animated_sprite.play("walk_" + last_direction)

func lock_movement() -> void:
	movement_locked = true
	velocity = Vector2.ZERO

func unlock_movement() -> void:
	movement_locked = false

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)

func _check_fall() -> void:
	if is_dead:
		return

	if not IslandBounds.is_inside_island(global_position):
		var fall_damage: int = int(max_health * fall_damage_percent)
		take_damage(fall_damage)
		global_position = IslandBounds.center_position
