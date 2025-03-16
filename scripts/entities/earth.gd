extends RigidBody2D

# Function to get the collision radius of the Earth
func get_collision_radius() -> float:
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		return collision_shape.shape.radius
	return 0.0
