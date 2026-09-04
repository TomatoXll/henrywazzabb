extends CanvasLayer

const RESPAWN_SCREEN_PATH := "res://respawn_screen.tscn"

func _ready() -> void:
	CursorManager.use_default_cursor()
	$HenryButton.pressed.connect(_on_henry_pressed)
	$DarpButton.pressed.connect(_on_darp_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

const HENRY_EDITOR_HUB_PATH := "res://henry_editor_hub.tscn"

func _on_henry_pressed() -> void:
	var hub_scene: PackedScene = load(HENRY_EDITOR_HUB_PATH)
	var hub := hub_scene.instantiate()
	get_tree().root.add_child(hub)
	queue_free()

const DARP_EDITOR_HUB_PATH := "res://darp_editor_hub.tscn"

func _on_darp_pressed() -> void:
	var hub_scene: PackedScene = load(DARP_EDITOR_HUB_PATH)
	var hub := hub_scene.instantiate()
	get_tree().root.add_child(hub)
	queue_free()

func _on_back_pressed() -> void:
	go_back_to_death_screen()

func go_back_to_death_screen() -> void:
	var respawn_screen_scene: PackedScene = load(RESPAWN_SCREEN_PATH)
	var respawn_screen := respawn_screen_scene.instantiate()
	get_tree().root.add_child(respawn_screen)
	queue_free()
