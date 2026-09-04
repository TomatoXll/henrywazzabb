extends CanvasLayer

const PLAYER_SCENE_PATH := "res://player.tscn"
const SLASH_ATTACK_SCENE_PATH := "res://slash_attack.tscn"
const HENRY_EDITOR_HUB_PATH := "res://henry_editor_hub.tscn"
const DARP_EDITOR_HUB_PATH := "res://darp_editor_hub.tscn"
const DEFAULT_DISPLAY_HEIGHT := 800.0
const CANVAS_POSITION := Vector2(67, 140)

var target_animation: String = ""
var frame_count: int = 1
var canvas_width: int = 60
var canvas_height: int = 80
var source_type: String = "player"

var current_frame_index: int = 0
var frame_images: Array[Image] = []
var frame_textures: Array[ImageTexture] = []
var selected_color: Color = Color.RED
var is_erasing: bool = false
var original_sprite_frames: SpriteFrames = null
var display_scale: float = 6.0
var dot_cursor_texture: Texture2D = preload("res://assets/curser.png")

func _ready() -> void:
	$InfoLabel.text = target_animation

	var display_size := Vector2(canvas_width * display_scale, canvas_height * display_scale)
	$DrawLayer.size = display_size
	$ReferenceLayer.size = display_size
	$DrawLayer.position = CANVAS_POSITION
	$ReferenceLayer.position = CANVAS_POSITION

	_load_original_sprite_frames()
	_init_frames()
	_show_current_frame()

	$DrawLayer.gui_input.connect(_on_draw_layer_gui_input)
	$DrawLayer.mouse_entered.connect(_on_draw_layer_mouse_entered)
	$DrawLayer.mouse_exited.connect(_on_draw_layer_mouse_exited)
	$PrevFrameButton.pressed.connect(_on_prev_frame)
	$NextFrameButton.pressed.connect(_on_next_frame)
	$EraserButton.pressed.connect(_on_eraser_pressed)
	$SaveButton.pressed.connect(_on_save_pressed)
	$ResetButton.pressed.connect(_on_reset_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

	$ColorPicker.color_changed.connect(_on_color_changed)
	$ColorPicker.color = selected_color

func _on_draw_layer_mouse_entered() -> void:
	Input.set_custom_mouse_cursor(dot_cursor_texture, Input.CURSOR_ARROW, Vector2(8, 8))

func _on_draw_layer_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)

func _load_original_sprite_frames() -> void:
	var scene_path: String = PLAYER_SCENE_PATH if source_type == "player" else SLASH_ATTACK_SCENE_PATH
	var source_scene: PackedScene = load(scene_path)
	var temp_instance := source_scene.instantiate()
	var sprite: AnimatedSprite2D = temp_instance.get_node("AnimatedSprite2D")
	original_sprite_frames = sprite.sprite_frames
	temp_instance.queue_free()

func _get_original_frame_image(index: int) -> Image:
	if original_sprite_frames and original_sprite_frames.has_animation(target_animation):
		var ref_count: int = original_sprite_frames.get_frame_count(target_animation)
		if ref_count > 0:
			var safe_index: int = min(index, ref_count - 1)
			var texture: Texture2D = original_sprite_frames.get_frame_texture(target_animation, safe_index)
			if texture:
				return texture.get_image()
	return Image.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)

func _get_save_folder() -> String:
	return "user://darp_custom/" if source_type == "slash_attack" else "user://henry_custom/"

func _init_frames() -> void:
	frame_images.clear()
	frame_textures.clear()

	var folder := _get_save_folder()

	for i in range(frame_count):
		var existing_path := "%s%s_%d.png" % [folder, target_animation, i]
		var img: Image
		if FileAccess.file_exists(existing_path):
			img = Image.load_from_file(existing_path)
		else:
			img = _get_original_frame_image(i).duplicate()
			img.convert(Image.FORMAT_RGBA8)
			if img.get_width() != canvas_width or img.get_height() != canvas_height:
				img.resize(canvas_width, canvas_height)
		frame_images.append(img)
		frame_textures.append(ImageTexture.create_from_image(img))

func _show_current_frame() -> void:
	$DrawLayer.texture = frame_textures[current_frame_index]
	$InfoLabel.text = "%s  (frame %d / %d)" % [target_animation, current_frame_index + 1, frame_count]
	var ref_image := _get_original_frame_image(current_frame_index)
	$ReferenceLayer.texture = ImageTexture.create_from_image(ref_image)

func _on_draw_layer_gui_input(event: InputEvent) -> void:
	var should_paint := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		should_paint = true
	elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		should_paint = true

	if should_paint:
		var px := int(event.position.x / display_scale)
		var py := int(event.position.y / display_scale)
		if px >= 0 and px < canvas_width and py >= 0 and py < canvas_height:
			var img := frame_images[current_frame_index]
			var color_to_use: Color = Color(0, 0, 0, 0) if is_erasing else selected_color
			img.set_pixel(px, py, color_to_use)
			frame_textures[current_frame_index].update(img)

func _on_prev_frame() -> void:
	current_frame_index = (current_frame_index - 1 + frame_count) % frame_count
	_show_current_frame()

func _on_next_frame() -> void:
	current_frame_index = (current_frame_index + 1) % frame_count
	_show_current_frame()

func _on_color_changed(new_color: Color) -> void:
	selected_color = new_color
	is_erasing = false

func _on_eraser_pressed() -> void:
	is_erasing = true

func _on_save_pressed() -> void:
	var folder := _get_save_folder()
	DirAccess.make_dir_recursive_absolute(folder)
	for i in range(frame_count):
		var path := "%s%s_%d.png" % [folder, target_animation, i]
		frame_images[i].save_png(path)
	print("Saved ", target_animation, " (", frame_count, " frames)")
	_on_back_pressed()

func _on_reset_pressed() -> void:
	var folder := _get_save_folder()
	for i in range(frame_count):
		var path := "%s%s_%d.png" % [folder, target_animation, i]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	_init_frames()
	_show_current_frame()
	print("Reset ", target_animation, " to default")

func _on_back_pressed() -> void:
	var hub_path: String = PLAYER_SCENE_PATH if false else (HENRY_EDITOR_HUB_PATH if source_type == "player" and target_animation != "attack" else DARP_EDITOR_HUB_PATH)
	if source_type == "player" and target_animation in ["walk_down", "walk_up", "walk_side", "idle_down", "idle_up"]:
		hub_path = HENRY_EDITOR_HUB_PATH
	else:
		hub_path = DARP_EDITOR_HUB_PATH

	var hub_scene: PackedScene = load(hub_path)
	var hub := hub_scene.instantiate()
	get_tree().root.add_child(hub)
	queue_free()
