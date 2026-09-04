extends Button

@export_multiline var hint_text: String = ""

func _pressed() -> void:
	HintManager.show_hint(hint_text, self)
