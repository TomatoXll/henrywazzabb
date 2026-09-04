extends CharacterBody2D

signal died

enum State { IDLE, TELEGRAPH, ATTACK, VULNERABLE }

@export var max_health: int = 500
@export var boss_name: String = "BOSS"
@export var idle_duration: float = 2.0
@export var telegraph_duration: float = 0.5
@export var attack_duration: float = 1.0
@export var vulnerable_duration: float = 1.5
@export var vulnerable_damage_multiplier: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var debug_color_rect: ColorRect = get_node_or_null("ColorRect")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var current_health: int
var current_state: State = State.IDLE
var state_timer: float = 0.0
var is_dead: bool = false
var is_locked_in_action: bool = false
var player: Node2D = null

func _ready() -> void:
	add_to_group("enemy")

	if debug_color_rect:
		debug_color_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
		debug_color_rect.position = -debug_color_rect.size / 2.0

	current_health = max_health
	player = get_tree().get_first_node_in_group("player")

	BossHud.show_boss_health(max_health, boss_name)

	_enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_locked_in_action:
		state_timer -= delta

		if state_timer <= 0.0:
			_advance_state()

	_process_current_state(delta)
	_check_fall()

func _check_fall() -> void:
	if is_dead or not player:
		return

	if not IslandBounds.is_inside_island(global_position):
		global_position = player.global_position

func _enter_state(new_state: State) -> void:
	current_state = new_state

	match current_state:
		State.IDLE:
			state_timer = idle_duration
		State.TELEGRAPH:
			state_timer = telegraph_duration
		State.ATTACK:
			state_timer = attack_duration
		State.VULNERABLE:
			state_timer = vulnerable_duration

	_update_debug_visual()

func _advance_state() -> void:
	match current_state:
		State.IDLE:
			_enter_state(State.TELEGRAPH)
		State.TELEGRAPH:
			_enter_state(State.ATTACK)
		State.ATTACK:
			_enter_state(State.VULNERABLE)
		State.VULNERABLE:
			_enter_state(State.IDLE)

func _process_current_state(_delta: float) -> void:
	pass

func _update_debug_visual() -> void:
	if not debug_color_rect:
		return

	match current_state:
		State.IDLE:
			debug_color_rect.color = Color(0.5, 0.5, 0.5)
		State.TELEGRAPH:
			debug_color_rect.color = Color(1.0, 0.9, 0.2)
		State.ATTACK:
			debug_color_rect.color = Color(0.9, 0.2, 0.2)
		State.VULNERABLE:
			debug_color_rect.color = Color(0.2, 0.8, 0.3)

func take_damage(amount: int) -> void:
	if is_dead:
		return

	var final_amount: int = amount
	if current_state == State.VULNERABLE:
		final_amount = int(amount * vulnerable_damage_multiplier)

	current_health -= final_amount
	BossHud.update_health(current_health)

	if current_health <= 0:
		die()

func apply_knockback(_direction: Vector2, _force: float) -> void:
	pass

func apply_status(_status_name: String, _damage_per_tick: int, _tick_interval: float, _duration: float) -> void:
	pass

func die() -> void:
	is_dead = true
	BossHud.hide_boss_health()
	print("Boss died")
	died.emit()
	queue_free()
