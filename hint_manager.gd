extends CanvasLayer

@onready var popup: PopupPanel = $HintPopupPanel
@onready var margin: MarginContainer = $HintPopupPanel/HintMargin
@onready var label: Label = $HintPopupPanel/HintMargin/HintLabel

func show_hint(text: String, anchor: Control) -> void:
	label.text = text
	await get_tree().process_frame

	var content_size: Vector2 = label.get_combined_minimum_size()
	var margin_left: int = margin.get_theme_constant("margin_left")
	var margin_right: int = margin.get_theme_constant("margin_right")
	var margin_top: int = margin.get_theme_constant("margin_top")
	var margin_bottom: int = margin.get_theme_constant("margin_bottom")

	var popup_size: Vector2 = content_size + Vector2(margin_left + margin_right, margin_top + margin_bottom)
	popup.size = Vector2i(popup_size)

	var anchor_pos: Vector2 = anchor.global_position
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	var target_position: Vector2 = anchor_pos + Vector2(0, anchor.size.y + 8)

	if target_position.y + popup_size.y > viewport_size.y:
		target_position.y = anchor_pos.y - popup_size.y - 8

	target_position.x = clamp(target_position.x, 8, viewport_size.x - popup_size.x - 8)

	popup.position = Vector2i(target_position)
	popup.popup()
