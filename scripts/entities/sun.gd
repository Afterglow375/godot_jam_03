extends Area2D

signal accuracy_score_changed(new_score: int)

@export var max_score: int = 100  # Max score when perfectly centered
var earth: RigidBody2D = null  # Store reference to the Earth
var updating_score: bool = false  # Track if we should update score
var accuracy_score: int = 0
var min_accuracy_score: int = 100 # Always award at least 100 points
var level: Node = null  # Reference to the level
var projectile_alive: bool = false  # Track if projectile is still alive
var level_won_flag: bool = false  # Flag to track if level has been won

# Distance-based sound variables
var last_earth_position: Vector2 = Vector2.ZERO  # Last position for distance tracking
var distance_traveled: float = 0.0  # Accumulated distance traveled
const SOUND_DISTANCE_THRESHOLD: float = 25.0  # Play sound every X pixels traveled

func _ready():
	# Store reference to the level
	level = get_tree().current_scene
	
	# Connect to the spaceship's signals
	var spaceship = get_node("../Spaceship")
	spaceship.projectile_created.connect(_on_projectile_created)

# Called when a projectile is created
func _on_projectile_created(projectile):
	projectile_alive = true
	# Connect to the projectile's destroyed signal
	projectile.projectile_destroyed.connect(_on_projectile_destroyed)
	
func _on_projectile_destroyed():
	projectile_alive = false

func _on_body_entered(body):
	if body.name == "Earth":
		earth = body  # Store reference to Earth
		updating_score = true  # Start updating score
		last_earth_position = earth.global_position  # Store initial position
		distance_traveled = 0.0  # Reset distance counter

func _on_body_exited(body):
	if body == earth:
		updating_score = false  # Stop updating score when Earth leaves
		earth = null  # Remove reference

func _process(delta):
	# Skip all processing if level has been won
	if level_won_flag:
		return
		
	if updating_score and earth:
		# Calculate distance and update score
		var distance_data = update_score()
		var distance_to_center = distance_data.distance
		var radius = distance_data.radius
		
		# Calculate distance traveled since last frame
		var current_position = earth.global_position
		var frame_distance = current_position.distance_to(last_earth_position)
		
		# Accumulate the distance traveled
		distance_traveled += frame_distance
		
		# Check if we've traveled enough to play the sound
		if distance_traveled >= SOUND_DISTANCE_THRESHOLD:
			distance_traveled = 0.0  # Reset counter
			
			# Calculate volume based on distance to center (closer = louder)
			var distance_ratio = clamp(distance_to_center / radius, 0.0, 1.0)
			
			AudioManager.play(AudioManager.Audio.SUN_HIT)
		
		# Store current position for next frame
		last_earth_position = current_position
		
		# When Earth stops moving and the projectile is no longer alive, trigger win
		if not earth.is_moving() and not projectile_alive:
			level.calculate_final_score(accuracy_score)
			level.level_won()
			level_won_flag = true  # Set flag to prevent further processing

# Updates the score and returns distance data for other calculations
func update_score() -> Dictionary:
	if not earth:  # Prevent errors if Earth is null
		return {"distance": 0, "radius": 0}

	var goal_center = global_position  # Sun's center
	var earth_position = earth.global_position  # Earth's position
	var distance = goal_center.distance_to(earth_position)

	var radius = $CollisionShape2D.shape.radius
	accuracy_score = calculate_score(distance, radius)
	
	# Emit signal when accuracy score changes
	accuracy_score_changed.emit(accuracy_score)
	
	return {"distance": distance, "radius": radius}

func calculate_score(distance: float, max_distance: float) -> int:
	var score = max_score * (1.0 - clamp(distance / max_distance, 0.0, 1.0)) + min_accuracy_score
	return round(score)
