extends Area2D

@export var repair_puzzle_scene: PackedScene

var player_in_zone: Node2D = null
var active_puzzle: Control = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print("RepairZone detected: ", body.name, " | is player: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		player_in_zone = body
		print("player_in_zone SET")

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_zone:
		player_in_zone = null

func _unhandled_input(event: InputEvent) -> void:
	if player_in_zone == null or active_puzzle != null:
		return

	if not RocketSystem.is_broken:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_start_repair()

func _start_repair() -> void:
	active_puzzle = repair_puzzle_scene.instantiate()
	get_tree().root.add_child(active_puzzle)
	active_puzzle.closed.connect(_on_puzzle_closed)
	player_in_zone.lock_movement()

func _on_puzzle_closed() -> void:
	if player_in_zone:
		player_in_zone.unlock_movement()
	active_puzzle = null
