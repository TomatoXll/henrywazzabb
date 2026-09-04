extends Node

var deformation_state: String = "normal"

func apply_deformation(deformation_type: String) -> void:
	if deformation_state == "normal":
		deformation_state = deformation_type
	elif deformation_state == deformation_type:
		pass
	else:
		deformation_state = "normal"

func clear_deformation() -> void:
	deformation_state = "normal"

func reset() -> void:
	deformation_state = "normal"
