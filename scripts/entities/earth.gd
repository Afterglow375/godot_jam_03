extends RigidBody2D

signal earth_stopped_moving

var was_moving: bool = false
var movement_threshold: float = 2.0  # Consider earth stopped when velocity is below this threshold

func _ready():
	# Enable contact monitoring for collision detection
	contact_monitor = true
	max_contacts_reported = 1

func _process(delta: float) -> void:
	var is_moving_bool: bool = is_moving()
	
	# Earth just started moving
	if is_moving_bool and not was_moving:
		was_moving = true
	
	# Earth just stopped moving
	elif not is_moving_bool and was_moving:
		earth_stopped_moving.emit()
		was_moving = false
		
func _physics_process(delta):
	if linear_velocity.length() < 10.0:  # If speed is very low
		linear_velocity = Vector2.ZERO  # Force stop
		
func is_moving() -> bool:
	return linear_velocity.length() > movement_threshold

# Function to get the collision radius of the Earth
func get_collision_radius() -> float:
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		return collision_shape.shape.radius
	return 0.0

func _on_body_entered(body):
	AudioManager.play(AudioManager.Audio.EARTH_WALL)
