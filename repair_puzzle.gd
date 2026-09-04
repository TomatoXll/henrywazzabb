extends Control

signal closed

const CODE_LINES: Array[String] = [
	"weapon_effect = \"fire\"",
	"enemy.burn_effect = True",
	"if sword.hit(enemy):",
	"import weapon_effect",
	"weapon_effect = \"ice\"",
	"enemy.freeze_effect = True",
]

@export var target_label: RichTextLabel
@export var input_field: LineEdit

var target_text: String = ""

func _ready() -> void:
	target_text = CODE_LINES[randi() % CODE_LINES.size()]
	target_label.bbcode_enabled = true
	_update_display()

	input_field.text_changed.connect(_on_text_changed)
	input_field.grab_focus()

func _on_text_changed(new_text: String) -> void:
	_update_display()

	if new_text == target_text:
		_on_repair_success()

func _update_display() -> void:
	var typed: String = input_field.text
	var display_text: String = ""

	for i in range(target_text.length()):
		var char_target: String = target_text[i]

		if i < typed.length():
			if typed[i] == char_target:
				display_text += "[color=green]%s[/color]" % char_target
			else:
				display_text += "[color=red]%s[/color]" % char_target
		else:
			display_text += "[color=gray]%s[/color]" % char_target

	target_label.text = display_text

func _on_repair_success() -> void:
	RocketSystem.repair_rocket()
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		closed.emit()
		queue_free()
