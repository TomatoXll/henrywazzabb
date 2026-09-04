extends CanvasLayer

@export var height_label: Label
@export var rocket_status_texture: TextureRect
@export var rocket_intact_texture: Texture2D
@export var rocket_broken_texture: Texture2D

func _ready() -> void:
	RocketSystem.rocket_broken.connect(_update_rocket_visual)
	RocketSystem.rocket_repaired.connect(_update_rocket_visual)
	_update_rocket_visual()

func _process(_delta: float) -> void:
	height_label.text = "Height: %d" % int(RocketSystem.current_height)

func _update_rocket_visual() -> void:
	if RocketSystem.is_broken:
		rocket_status_texture.texture = rocket_broken_texture
	else:
		rocket_status_texture.texture = rocket_intact_texture
