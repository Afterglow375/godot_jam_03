extends RigidBody2D

var earth_wall: AudioStreamPlayer = null

func _ready():
	earth_wall = $EarthWallSound
	# Enable contact monitoring for collision detection
	contact_monitor = true
	max_contacts_reported = 1

# Function to get the collision radius of the Earth
func get_collision_radius() -> float:
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		return collision_shape.shape.radius
	return 0.0

func _on_body_entered(body):
	earth_wall.play()
