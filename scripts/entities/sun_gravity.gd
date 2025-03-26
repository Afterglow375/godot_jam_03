extends Area2D

var earth: RigidBody2D = null  # Store reference to the Earth
var radius: float = 0.0       # Store the radius of the gravity area
const MAX_GRAVITY_FORCE: float = 300.0  # Maximum gravity force at the edge
const MIN_GRAVITY_FORCE: float = 100.0   # Minimum gravity force near center
const GRAVITY_DURATION: float = 1.0     # How long to apply gravity in seconds
var gravity_timer: float = 0.0          # Track how long gravity has been applied

@onready var game_manager = get_node("/root/GameManager")

# Called when the node enters the scene tree for the first time.
func _ready():
	earth = get_node("/root/Main/Earth")  # Get Earth reference from root
	earth.earth_stopped_moving.connect(_on_earth_stopped_moving)
	
	# Get the radius of the circular collision shape
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape:
		radius = collision_shape.shape.radius

func _on_earth_stopped_moving():
	gravity_timer = 0.0  # Reset timer when Earth stops moving

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if game_manager.is_paused():
		return
		
	if earth.is_moving() and gravity_timer < GRAVITY_DURATION:
		# Calculate distance from Earth to center of gravity area
		var direction_to_sun: Vector2 = global_position - earth.global_position
		var distance: float = direction_to_sun.length()
		
		# Only apply force if Earth is within the area
		if distance > radius:
			return
		
		# Normalize direction for force application
		direction_to_sun = direction_to_sun.normalized()
		
		# Get Earth's velocity direction
		var velocity_direction: Vector2 = earth.linear_velocity.normalized()
		
		# Calculate dot product between velocity and direction to sun
		# This will be 1 when moving directly towards sun, -1 when moving directly away
		# and 0 when moving perpendicular to sun
		var dot_product: float = velocity_direction.dot(direction_to_sun)
		
		# Calculate force based on distance and perpendicularity
		# abs(dot_product) will be 0 when moving perpendicular to sun (strongest effect)
		# and 1 when moving directly towards/away from sun (no effect)
		var perpendicular_factor: float = 1.0 - abs(dot_product)
		var force_magnitude: float = MAX_GRAVITY_FORCE * (distance / radius) * perpendicular_factor
		force_magnitude = clamp(force_magnitude, MIN_GRAVITY_FORCE, MAX_GRAVITY_FORCE)
		
		# Apply the distance-based gravitational force
		earth.apply_force(direction_to_sun * force_magnitude)
		
		# Update timer
		gravity_timer += delta
