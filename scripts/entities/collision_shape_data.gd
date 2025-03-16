extends CollisionShape2D

# Signal to notify when radius changes
signal radius_changed(new_radius: float)

func _ready() -> void:
	# Emit initial radius if it's a circle shape
	if shape is CircleShape2D:
		emit_signal("radius_changed", shape.radius)

# Call this when you want to get the current radius
func get_radius() -> float:
	if shape is CircleShape2D:
		return shape.radius
	return 0.0

# You can also add a setter if you want to modify the radius programmatically
func set_radius(new_radius: float) -> void:
	if shape is CircleShape2D:
		shape.radius = new_radius
		emit_signal("radius_changed", new_radius) 
