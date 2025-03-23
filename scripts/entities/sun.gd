extends Area2D

@export var max_score: int = 100  # Max score when perfectly centered
var earth: RigidBody2D = null  # Store reference to the Earth
var updating_score: bool = false  # Track if we should update score
var accuracy_score: int = 0
var level: Node = null  # Reference to the level
var projectile_alive: bool = false  # Track if projectile is still alive

# Get reference to the AudioManager singleton
@onready var audio_manager = get_node("/root/AudioManager")

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

func _on_body_exited(body):
	if body == earth:
		updating_score = false  # Stop updating score when Earth leaves
		earth = null  # Remove reference

func _process(delta):
	if updating_score and earth:
		# Always update score as long as Earth is in sun
		update_score()
		
		# When Earth stops moving and the projectile is no longer alive, trigger win
		if not earth.is_moving() and not projectile_alive:
			level.calculate_final_score(accuracy_score)
			level.level_won()

func update_score():
	if not earth:  # Prevent errors if Earth is null
		return

	var goal_center = global_position  # Sun's center
	var earth_position = earth.global_position  # Earth's position
	var distance = goal_center.distance_to(earth_position)

	var radius = ($CollisionShape2D.shape.radius) if $CollisionShape2D.shape is CircleShape2D else 100
	accuracy_score = calculate_score(distance, radius)

func calculate_score(distance: float, max_distance: float) -> int:
	var score = max_score * (1.0 - clamp(distance / max_distance, 0.0, 1.0))
	return round(score)
