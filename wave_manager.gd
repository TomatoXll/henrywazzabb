extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_distance: float = 600.0
@export var base_health: int = 15
@export var health_multiplier_per_wave: float = 2.0
@export var speed_increase_per_wave: float = 5.0
@export var base_enemies_per_wave: int = 10
@export var enemy_count_increase_per_wave: int = 5
@export var max_enemies_per_wave: int = 200
@export var spawn_stagger_delay: float = 0.2
@export var next_wave_delay: float = 3.0

var player: Node2D = null
var current_wave: int = 1
var enemies_alive: int = 0
var is_spawning: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	start_wave()

func start_wave() -> void:
	print("Wave ", current_wave, " starting! Enemies: ", get_enemies_this_wave(), " Health: ", get_current_health())
	is_spawning = true
	_spawn_wave_enemies()

func _spawn_wave_enemies() -> void:
	var total: int = get_enemies_this_wave()

	for i in range(total):
		spawn_enemy()
		await get_tree().create_timer(spawn_stagger_delay).timeout

	is_spawning = false
	_check_wave_cleared()

func get_enemies_this_wave() -> int:
	var count: int = base_enemies_per_wave + enemy_count_increase_per_wave * (current_wave - 1)
	return min(count, max_enemies_per_wave)

func get_current_health() -> int:
	return int(base_health * pow(health_multiplier_per_wave, current_wave - 1))

func spawn_enemy() -> void:
	if player == null or enemy_scene == null:
		return

	var enemy_instance := enemy_scene.instantiate()

	var angle := randf() * TAU
	var offset := Vector2.RIGHT.rotated(angle) * spawn_distance
	var spawn_position: Vector2 = player.global_position + offset

	enemy_instance.max_health = get_current_health()
	enemy_instance.speed = 100.0 + (current_wave - 1) * speed_increase_per_wave
	enemy_instance.position = spawn_position

	enemy_instance.died.connect(_on_enemy_died)
	enemies_alive += 1

	get_parent().add_child.call_deferred(enemy_instance)
	
func _on_enemy_died() -> void:
	enemies_alive -= 1
	_check_wave_cleared()

func _check_wave_cleared() -> void:
	if enemies_alive <= 0 and not is_spawning:
		_advance_to_next_wave()

func _advance_to_next_wave() -> void:
	current_wave += 1
	print("Wave cleared! Next wave in ", next_wave_delay, " seconds...")
	await get_tree().create_timer(next_wave_delay).timeout
	start_wave()
