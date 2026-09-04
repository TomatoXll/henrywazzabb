extends StaticBody2D

func take_hit() -> void:
	RocketSystem.register_rocket_hit()
	print("Rocket hits: ", RocketSystem.current_hits)
