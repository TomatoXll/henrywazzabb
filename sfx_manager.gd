extends Node

@onready var click_player: AudioStreamPlayer = $ClickPlayer

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(_play_click)

func _play_click() -> void:
	click_player.stop()
	click_player.play()
