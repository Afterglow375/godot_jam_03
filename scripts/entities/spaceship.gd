extends Area2D

const MAX_LINE_LENGTH: float = 500.0  # Adjust this value to change max length
const ProjectileScene: PackedScene = preload("res://scenes/entities/projectile.tscn")

var is_mouse_held: bool = false
var line: Line2D
var trajectory_line: Line2D = null  # Line for trajectory
var current_line_end: Vector2 = Vector2.ZERO
var drag_started_in_area: bool = false
var level: Node = null  # Reference to the level
var ray_cast: RayCast2D = null  # RayCast for collision detection
var shoot_sound: AudioStreamPlayer = null

func _ready():
	line = $SlingshotLine
	trajectory_line = $TrajectoryLine
	ray_cast = $TrajectoryRaycast
	shoot_sound = $ShootSound
	
	# Store reference to the level
	level = get_tree().current_scene
	
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drag_started_in_area = true
			is_mouse_held = true

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if drag_started_in_area:  # Only launch if drag started in area
				launch_projectile()
				drag_started_in_area = false
			
				line.clear_points()
				trajectory_line.clear_points()
			is_mouse_held = false

func _process(delta):
	if is_mouse_held:
		var mouse_pos: Vector2 = get_local_mouse_position()
		var length: float = mouse_pos.length()
		
		# Draw the line with clamped length if needed
		current_line_end = mouse_pos
		if length > MAX_LINE_LENGTH:
			current_line_end = mouse_pos.normalized() * MAX_LINE_LENGTH
		
		# Draw the input line
		line.clear_points()
		line.add_point(Vector2.ZERO)  # Center of the Area2D
		line.add_point(current_line_end)  # Clamped position for line
		
		# Calculate the direction and show trajectory 
		var direction: Vector2 = -current_line_end.normalized()
		
		# Update trajectory line using raycast
		update_trajectory_line(direction)

# Updates the trajectory line using a raycast to detect wall collisions
func update_trajectory_line(direction: Vector2) -> void:
	trajectory_line.clear_points()
	
	# Add start point (spaceship position)
	trajectory_line.add_point(Vector2.ZERO)
	
	# Set raycast direction and distance
	ray_cast.target_position = direction * 5000  # Long enough to hit any wall
	ray_cast.force_raycast_update()
	
	# Add endpoint based on collision
	if ray_cast.is_colliding():
		# Get collision point in local coordinates
		var collision_point: Vector2 = to_local(ray_cast.get_collision_point())
		trajectory_line.add_point(collision_point)
	else:
		# If no collision, just show a very long line
		trajectory_line.add_point(direction * 2000)

func launch_projectile() -> void:
	if current_line_end.length() > 0:
		var projectile: Node = ProjectileScene.instantiate()
		get_parent().add_child(projectile)
		projectile.position = position
		
		# Calculate speed multiplier based on line length (0.0 to 1.0)
		var speed_multiplier: float = current_line_end.length() / MAX_LINE_LENGTH
		
		# Launch in the direction of the line with speed based on length
		projectile.launch(current_line_end.normalized(), speed_multiplier)
		
		# Increment the score
		increment_score()
		
		shoot_sound.play()

# Add 1 to the score
func increment_score() -> void:
	# Use the stored level reference
	level.add_score(1)
