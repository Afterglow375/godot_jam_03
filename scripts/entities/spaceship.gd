extends Area2D

signal projectile_created(projectile)

const MAX_LINE_LENGTH: float = 500.0  # Adjust this value to change max length
const ProjectileScene: PackedScene = preload("res://scenes/entities/projectile.tscn")
const MAX_BOUNCES: int = 5  # Maximum number of bounces to simulate
const BASE_SPEED: float = 2000.0  # Match the value from projectile_container.gd

var is_mouse_held: bool = false
var line: Line2D
var trajectory_line: Line2D = null  # Line for trajectory
var trajectory_end: Sprite2D = null  # Reference to the end sprite
var current_line_end: Vector2 = Vector2.ZERO
var drag_started_in_area: bool = false
var level: Node = null  # Reference to the level
var ray_cast: RayCast2D = null  # RayCast for collision detection
var can_shoot: bool = true  # True if user can shoot from spaceship, false if can't
var earth: RigidBody2D = null  # Reference to the Earth node
var sprite: Sprite2D = null  # Reference to the sprite node
var target_rotation: float = 0.0  # Target rotation for smooth rotation
var target_scale_x: float = 1.0  # Target x scale for smooth flipping
var target_scale: Vector2 = Vector2(1.0, 1.0)  # Target scale for hover effect
var base_scale: Vector2 = Vector2(1.0, 1.0)  # Base scale of the sprite
var hover_scale: Vector2 = Vector2(1.2, 1.2)  # Scale when hovered
var rotation_speed: float = 10.0  # Adjust for faster/slower rotation
var is_hovered: bool = false  # Whether the mouse is hovering over the Area2D
var speed_multiplier: float = 0.0  # Speed multiplier based on line length

func _ready():
	line = $SlingshotLine
	trajectory_line = $TrajectoryLine
	trajectory_end = $TrajectoryEnd
	ray_cast = $TrajectoryRaycast
	sprite = $Sprite2D  # Get reference to the spaceship sprite
	base_scale = sprite.scale  # Store the original scale
	
	# Hide trajectory end sprite initially
	if trajectory_end:
		trajectory_end.visible = false
	
	# Store reference to the level
	level = get_tree().current_scene
	
	# Get reference to the Earth node
	earth = get_node("../Earth")
	
	# Connect to the Earth's signal
	earth.earth_stopped_moving.connect(_on_earth_stopped_moving)
	
	# Connect to the win popup's victory signal - need to wait until level is ready
	call_deferred("connect_to_win_popup")
	
	# Connect mouse enter/exit signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
func connect_to_win_popup() -> void:
	# The win popup is added by the level script, ensure it exists now
	level.win_popup.victory_achieved.connect(_on_victory_achieved)
	
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_shoot:
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
				
				# Hide trajectory end sprite
				if trajectory_end:
					trajectory_end.visible = false
					
			is_mouse_held = false

func _process(delta):
	if is_mouse_held:
		var mouse_pos: Vector2 = get_local_mouse_position()
		var length: float = mouse_pos.length()
		
		# Draw the line with clamped length if needed
		current_line_end = mouse_pos
		if length > MAX_LINE_LENGTH:
			current_line_end = mouse_pos.normalized() * MAX_LINE_LENGTH
		
		level.update_charge_bar(length)
		
		# Draw the input line
		line.clear_points()
		line.add_point(Vector2.ZERO)  # Center of the Area2D
		line.add_point(current_line_end)  # Clamped position for line
		
		# Calculate the direction and show trajectory 
		var direction: Vector2 = -current_line_end.normalized()
		
		# Calculate speed multiplier based on line length (0.0 to 1.0)
		speed_multiplier = current_line_end.length() / MAX_LINE_LENGTH
		
		# Update trajectory line using raycast with bounces
		update_trajectory_line(direction)
		
		# Rotate only the spaceship sprite to point away from the mouse cursor
		if mouse_pos != Vector2.ZERO:  # Avoid division by zero
			# Determine if mouse is on the right side
			var is_right_side: bool = mouse_pos.x > 0
			
			# Set target x scale based on mouse position
			target_scale_x = -1 if is_right_side else 1
			
			# Calculate angle away from mouse position
			var angle: float = mouse_pos.angle()
			
			# Set target rotation based on which side the mouse is on
			if is_right_side:
				# Base rotation that makes sprite point away from the mouse
				target_rotation = angle
			else:
				# Normal rotation when on the left side
				target_rotation = angle + PI
	else:
		# When mouse is not held, set targets to return to original position
		target_rotation = 0.0
		target_scale_x = 1.0
		
		# Hide trajectory end sprite when not drawing
		if trajectory_end and trajectory_end.visible:
			trajectory_end.visible = false
	
	# Set target scale based on hover state
	if is_hovered or is_mouse_held:
		target_scale = hover_scale
	else:
		target_scale = base_scale
	
	# Apply smooth rotation and scaling
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, delta * rotation_speed)
	sprite.scale.x = lerp(sprite.scale.x, target_scale_x * target_scale.x, delta * rotation_speed)
	sprite.scale.y = lerp(sprite.scale.y, target_scale.y, delta * rotation_speed)

# Updates the trajectory line with multiple bounces
func update_trajectory_line(direction: Vector2) -> void:
	trajectory_line.clear_points()
	
	# Make sure trajectory starts at the same position as the slingshot line
	trajectory_line.add_point(Vector2.ZERO)  # Center of the Area2D/spaceship
	
	var current_position: Vector2 = Vector2.ZERO  # Start at the center of the spaceship
	var current_direction: Vector2 = direction
	var velocity: Vector2 = direction * (BASE_SPEED * speed_multiplier)
	
	# Further reduce effective lifetime to match actual visual behavior
	var effective_lifetime: float = 4  # Experimentally adjusted for visual accuracy
	
	# Store the final trajectory point for the end sprite
	var final_trajectory_point: Vector2 = Vector2.ZERO
	
	# Keep track of the last valid collision normal for fallback
	var last_valid_normal: Vector2 = Vector2.ZERO
	
	# Process bounces
	for bounce in range(MAX_BOUNCES + 1):  # +1 for initial ray
		# If no more lifetime, stop calculating
		if effective_lifetime <= 0:
			break
			
		# Offset the raycast position slightly to avoid self-collision issues
		var raycast_start_position = current_position + current_direction * 0.1
		
		# Set raycast direction and distance
		ray_cast.global_position = to_global(raycast_start_position)
		ray_cast.target_position = current_direction * 5000  # Long distance to ensure we hit walls
		ray_cast.force_raycast_update()
		
		if ray_cast.is_colliding():
			var collision_point: Vector2 = to_local(ray_cast.get_collision_point())
			var collision_normal: Vector2 = ray_cast.get_collision_normal()
			
			# Handle zero or invalid normals
			if collision_normal.length_squared() < 0.01:
				if last_valid_normal != Vector2.ZERO:
					collision_normal = last_valid_normal
				else:
					# If we don't have a valid normal from before, use a perpendicular to direction
					collision_normal = Vector2(-current_direction.y, current_direction.x).normalized()
			else:
				# Store this valid normal for future use
				last_valid_normal = collision_normal
			
			# Ensure the normal is normalized
			collision_normal = collision_normal.normalized()
			
			# Calculate time to reach collision point
			var distance_to_collision: float = (collision_point - current_position).length()
			var time_to_collision: float = distance_to_collision / velocity.length()
			
			# If we would run out of lifetime before hitting the wall
			if time_to_collision > effective_lifetime:
				# Calculate where the projectile would fizzle out
				var max_distance: float = velocity.length() * effective_lifetime
				var fizzle_point: Vector2 = current_position + current_direction * max_distance
				trajectory_line.add_point(fizzle_point)
				final_trajectory_point = fizzle_point
				break
			
			# Add a point slightly before the collision point to fix visual glitches
			var pre_collision_point: Vector2 = collision_point - current_direction * 0.5
			trajectory_line.add_point(pre_collision_point)
			
			# Add collision point to trajectory
			trajectory_line.add_point(collision_point)
			
			# Calculate bounce direction with special handling for vertical surfaces
			var bounced_direction: Vector2
			if current_direction.y < -0.7 and collision_normal.y > 0.7:
				# For upward trajectories hitting downward-facing surfaces, use a simpler bounce
				bounced_direction = Vector2(current_direction.x, -current_direction.y)
			else:
				# Use the standard bounce for all other cases
				bounced_direction = current_direction.bounce(collision_normal)
			
			# Add a small random perturbation to avoid getting stuck in identical bounce patterns
			bounced_direction = bounced_direction.normalized()
			
			# Ensure the bounced direction is valid
			if bounced_direction.length_squared() < 0.01:
				bounced_direction = Vector2(-current_direction.x, -current_direction.y).normalized()
			
			# Add a point slightly after the collision with the new direction to fix visual glitches
			var post_collision_point: Vector2 = collision_point + bounced_direction * 0.5
			trajectory_line.add_point(post_collision_point)
			
			# Update remaining lifetime
			effective_lifetime -= time_to_collision
			
			# If this was our last bounce, stop
			if bounce == MAX_BOUNCES:
				final_trajectory_point = collision_point
				break
				
			# Update direction and position for next raycast
			current_direction = bounced_direction
			current_position = collision_point
		else:
			# No collision, calculate fizzle point based on remaining lifetime
			var max_distance: float = velocity.length() * effective_lifetime
			var fizzle_point: Vector2 = current_position + current_direction * max_distance
			trajectory_line.add_point(fizzle_point)
			final_trajectory_point = fizzle_point
			break
	
	# Update trajectory end sprite position and visibility
	if trajectory_end and trajectory_line.get_point_count() > 0:
		# Show and position the end sprite at the final trajectory point
		trajectory_end.visible = true
		trajectory_end.position = final_trajectory_point

func launch_projectile() -> void:
	if current_line_end.length() > 0:
		var projectile_container = ProjectileScene.instantiate()
		get_parent().add_child(projectile_container)
		projectile_container.position = position
		
		# Wait one frame for the viewport to initialize properly
		await get_tree().process_frame
		
		# Connect to the projectile container's destruction signal
		projectile_container.projectile_destroyed.connect(_on_projectile_destroyed)
		
		# Calculate speed multiplier based on line length (0.0 to 1.0)
		var speed_multiplier: float = current_line_end.length() / MAX_LINE_LENGTH
		
		# Launch in the direction of the line with speed based on length
		projectile_container.launch(current_line_end.normalized(), speed_multiplier)
		
		# Emit signal that projectile was created
		projectile_created.emit(projectile_container)
		
		# Increment the score
		increment_score()
		
		# Disable shooting until reset externally
		can_shoot = false
		
		level.update_charge_bar(0)

# Handle projectile destroyed signal
func _on_projectile_destroyed() -> void:
	# Check if Earth is moving below threshold
	if earth and earth.linear_velocity.length() <= earth.movement_threshold:
		# Earth is not moving significantly, enable shooting immediately
		can_shoot = true
	# Otherwise wait for earth_stopped_moving signal

# Handle earth stopped moving signal
func _on_earth_stopped_moving() -> void:
	# Enable shooting when Earth stops moving
	can_shoot = true

# Handle victory achieved signal
func _on_victory_achieved() -> void:
	# Disable shooting when level is won
	can_shoot = false
	
	# Clear any active shooting UI
	if is_mouse_held:
		is_mouse_held = false
		line.clear_points()
		trajectory_line.clear_points()
		
		# Hide trajectory end sprite
		if trajectory_end:
			trajectory_end.visible = false

# Add 1 to the score
func increment_score() -> void:
	# Use the stored level reference
	level.add_score(1)

# Handle mouse entered signal
func _on_mouse_entered() -> void:
	is_hovered = true

# Handle mouse exited signal
func _on_mouse_exited() -> void:
	is_hovered = false
