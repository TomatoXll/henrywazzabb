extends Node2D

@onready var boundary_shape: Polygon2D = $BoundaryShape

@export var center_position: Vector2 = Vector2.ZERO

func is_inside_island(world_position: Vector2) -> bool:
	var local_position: Vector2 = boundary_shape.to_local(world_position)
	return Geometry2D.is_point_in_polygon(local_position, boundary_shape.polygon)
