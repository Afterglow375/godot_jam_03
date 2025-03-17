extends Area2D

@export var max_score: int = 100  # Max score when perfectly centered
@onready var earth: RigidBody2D = null  # Store reference to the Earth
var updating_score: bool = false  # Track if we should update score
var accuracy_score: int = 0
var level: Node = null  # Reference to the level

func _ready():
	# Store reference to the level
	level = get_tree().current_scene
	
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
		if earth.linear_velocity.length() > 2:  # Only update if Earth is actually moving
			update_score()
		else:
			updating_score = false  # Stop updating when Earth stops moving
			round_win() # Triggers when earth is inside the sun area and stops moving

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

func round_win():
	level.calculate_final_score(accuracy_score)
	level.level_won()
