extends Area2D

signal projectile_created(projectile)
signal angle_changed(new_angle)
signal update_charge_bar_requested(value)
signal add_shot_requested(value)

const MAX_LINE_LENGTH: float = 500.0  # Adjust this value to change max length
const PushProjectileScene: PackedScene = preload("res://scenes/entities/push_projectile.tscn")
const PullProjectileScene: PackedScene = preload("res://scenes/entities/pull_projectile.tscn")
const MAX_BOUNCES: int = 8  # Maximum number of bounces to simulate
const BASE_SPEED: float = 2000.0  # Match the value from projectile_container.gd

var is_mouse_held: bool = false
var line: Line2D
var trajectory_line: Line2D = null  # Line for trajectory
var trajectory_end: Sprite2D = null  # Reference to the end sprite
var current_line_end: Vector2 = Vector2.ZERO
var drag_started_in_area: bool = false
var ray_cast: RayCast2D = null  # RayCast for collision detection
var can_shoot: bool = true  # True if user can shoot from spaceship, false if can't
var earth: RigidBody2D = null  # Reference to the Earth node
var sprite: Sprite2D = null  # Reference to the sprite node
var push_overlay: Sprite2D = null  # Reference to the push projectile overlay
var pull_overlay: Sprite2D = null  # Reference to the pull projectile overlay
var target_rotation: float = 0.0  # Target rotation for smooth rotation
var target_scale_x: float = 1.0  # Target x scale for smooth flipping
var target_scale: Vector2 = Vector2(1.0, 1.0)  # Target scale for hover effect
var base_scale: Vector2 = Vector2(1.0, 1.0)  # Base scale of the sprite
var hover_scale: Vector2 = Vector2(1.2, 1.2)  # Scale when hovered
var rotation_speed: float = 10.0  # Adjust for faster/slower rotation
var is_hovered: bool = false  # Whether the mouse is hovering over the Area2D
var speed_multiplier: float = 0.0  # Speed multiplier based on line length
var trajectory_points: Array[Vector2] = []  # List to store trajectory points
var is_calculating_trajectory: bool = false  # Flag to indicate if trajectory needs updating
var is_precision_aiming: bool = false  # Flag for precision aiming mode
var precision_factor: float = 0.05  # Reduces mouse sensitivity by 95% when precision aiming
var processed_mouse_pos: Vector2 = Vector2.ZERO  # Processed mouse position with precision/snapping applied
var last_mouse_pos: Vector2 = Vector2.ZERO  # Store the last mouse position for delta calculation
var accumulated_mouse_pos: Vector2 = Vector2.ZERO  # Accumulated mouse position for precision mode
var raw_mouse_pos: Vector2 = Vector2.ZERO  # Original mouse position without any processing
var aim_position: Vector2 = Vector2.ZERO  # Position used for aiming that accounts for precision

# Bobbing animation variables
var bobbing_speed: float = 2.0
var bobbing_amount: float = 5.0
var bobbing_time: float = 0.0
var original_position: Vector2 = Vector2.ZERO
var stored_mouse_position: Vector2 = Vector2.ZERO  # Store mouse position when capturing it

func _ready():
	line = $SlingshotLine
	trajectory_line = $TrajectoryLine
	trajectory_end = $TrajectoryEnd
	ray_cast = $TrajectoryRaycast
	sprite = $Sprite2D  # Get reference to the spaceship sprite
	base_scale = sprite.scale  # Store the original scale
	
	# Store the original position of the sprite
	original_position = sprite.position
	
	# Initialize accumulated mouse position
	accumulated_mouse_pos = Vector2.ZERO
	
	# Get references to overlay sprites
	push_overlay = $PushOverlay
	pull_overlay = $PullOverlay
	
	# Initialize projectile overlays based on GameManager state
	update_projectile_overlays()
	
	# Connect to GameManager's projectile type changed signal
	GameManager.projectile_type_changed.connect(_on_projectile_type_changed)
	
	# Hide trajectory end sprite initially
	if trajectory_end:
		trajectory_end.visible = false
	
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
	var win_popup = get_node("../UI/WinPopup")
	win_popup.victory_achieved.connect(_on_victory_achieved)
	
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_shoot:
			drag_started_in_area = true
			is_mouse_held = true
			is_calculating_trajectory = true
			
			# Store the current mouse position before capturing
			stored_mouse_position = get_viewport().get_mouse_position()
			
			# Capture mouse for unlimited movement
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
			# Reset accumulated mouse position when starting a new drag
			accumulated_mouse_pos = Vector2.ZERO
			last_mouse_pos = get_local_mouse_position()

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
			
				# Only release mouse capture if we had captured it
				if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					get_viewport().warp_mouse(stored_mouse_position)
			
			is_mouse_held = false
			
			# Reset accumulated mouse position when releasing
			accumulated_mouse_pos = Vector2.ZERO
	
	# Handle mouse movement only when drag started in spaceship area
	elif event is InputEventMouseMotion and is_mouse_held and drag_started_in_area and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion = event.relative
		
		# Apply the motion to our accumulated position with sensitivity adjustments
		if is_precision_aiming:
			accumulated_mouse_pos += motion * precision_factor
		else:
			accumulated_mouse_pos += motion
		
		# Clamp the accumulated mouse position to MAX_LINE_LENGTH
		if accumulated_mouse_pos.length() > MAX_LINE_LENGTH:
			accumulated_mouse_pos = accumulated_mouse_pos.normalized() * MAX_LINE_LENGTH
	
	# Toggle between push and pull projectiles with spacebar
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and can_shoot:
		GameManager.toggle_projectile_type()

func _physics_process(delta):
	if is_calculating_trajectory and is_mouse_held:
		# Use the processed mouse position that's calculated in _process
		var direction: Vector2 = -processed_mouse_pos.normalized()
		
		if processed_mouse_pos.length() > 5.0:
			calculate_trajectory_points(direction)
		else:
			trajectory_points.clear()

func calculate_trajectory_points(direction: Vector2) -> void:
	# Clear existing points
	trajectory_points.clear()
	
	# Add the starting point (spaceship position)
	trajectory_points.append(Vector2.ZERO)
	
	var current_position: Vector2 = Vector2.ZERO
	var current_direction: Vector2 = direction
	
	# Loop through each potential bounce
	for bounce in range(MAX_BOUNCES + 1):
		# Add a small offset to avoid self-collision
		var raycast_start = current_position + current_direction * 2.0
		
		# Set raycast position and direction
		ray_cast.global_position = to_global(raycast_start)
		ray_cast.target_position = current_direction * 5000
		ray_cast.force_raycast_update()
		
		if ray_cast.is_colliding():
			# Get collision information
			var collision_point = to_local(ray_cast.get_collision_point())
			var collision_normal = ray_cast.get_collision_normal()
			
			# Make sure normal is valid
			if collision_normal.length_squared() < 0.01:
				# Invalid normal, use a perpendicular vector
				collision_normal = Vector2(-current_direction.y, current_direction.x).normalized()
			
			# Add a point slightly before the collision for better visualization
			var pre_collision = collision_point - current_direction * 2.0
			trajectory_points.append(pre_collision)
			
			# Add the collision point
			trajectory_points.append(collision_point)
						
			# Calculate the reflected direction
			var reflection = current_direction.bounce(collision_normal)
			reflection = reflection.normalized()
			
			# Add a point slightly after collision in the new direction
			var post_collision = collision_point + reflection * 2.0
			trajectory_points.append(post_collision)
			
			# Setup for next bounce
			current_position = collision_point
			current_direction = reflection
			
			# If we've reached the max bounces, exit
			if bounce == MAX_BOUNCES:
				break
		else:
			# No collision, add a point far in the direction
			var far_point = current_position + current_direction * 5000
			trajectory_points.append(far_point)
			break  # End the trajectory

func _process(delta):
	if GameManager.is_paused():
		return
	
	# Update bobbing animation
	bobbing_time += delta * bobbing_speed
	var bobbing_offset = sin(bobbing_time) * bobbing_amount
	sprite.position.y = original_position.y + bobbing_offset
	
	# Check shift key state every frame
	is_precision_aiming = Input.is_key_pressed(KEY_SHIFT)
	
	if is_mouse_held:
		var current_mouse_pos: Vector2 = Vector2.ZERO
		var mouse_delta: Vector2 = Vector2.ZERO
		
		# If not in captured mode (fallback), use the normal local mouse position
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			current_mouse_pos = get_local_mouse_position()
			
			if last_mouse_pos != Vector2.ZERO:
				mouse_delta = current_mouse_pos - last_mouse_pos
			
			last_mouse_pos = current_mouse_pos
			
			if is_precision_aiming:
				accumulated_mouse_pos += mouse_delta * precision_factor
			else:
				accumulated_mouse_pos = current_mouse_pos
			
			# Clamp the accumulated mouse position to MAX_LINE_LENGTH
			if accumulated_mouse_pos.length() > MAX_LINE_LENGTH:
				accumulated_mouse_pos = accumulated_mouse_pos.normalized() * MAX_LINE_LENGTH
		
		var mouse_pos: Vector2 = accumulated_mouse_pos
		var original_length: float = mouse_pos.length()
		
		# Apply angle snapping based on precision mode
		if is_precision_aiming:
			var angle: float = mouse_pos.angle()
			var snap_angle: float = snappedf(rad_to_deg(angle), 0.01)  # Snap to 0.01 degree increments
			angle = deg_to_rad(snap_angle)
			mouse_pos = Vector2(cos(angle), sin(angle)) * original_length
		else:
			var angle: float = mouse_pos.angle()
			var snap_angle: float = snappedf(rad_to_deg(angle), 1.0)  # Snap to whole degrees
			angle = deg_to_rad(snap_angle)
			mouse_pos = Vector2(cos(angle), sin(angle)) * original_length
		
		processed_mouse_pos = mouse_pos
		
		# Draw the line with clamped length if needed
		current_line_end = mouse_pos
		# We still need to apply MAX_LINE_LENGTH clamping to the line itself
		if original_length > MAX_LINE_LENGTH:
			current_line_end = mouse_pos.normalized() * MAX_LINE_LENGTH
		
		update_charge_bar_requested.emit(original_length)
		
		# Draw the input line
		line.clear_points()
		line.add_point(Vector2.ZERO)  # Center of the Area2D
		line.add_point(current_line_end)  # Clamped position for line
		
		# Calculate the direction and show trajectory 
		var direction: Vector2 = -current_line_end.normalized()
		
		# Calculate speed multiplier based on line length (0.0 to 1.0)
		speed_multiplier = current_line_end.length() / MAX_LINE_LENGTH
		
		# Update trajectory line using stored points
		update_trajectory_line()
		
		# Rotate only the spaceship sprite to point away from the mouse cursor
		if mouse_pos != Vector2.ZERO:  # Avoid division by zero
			# Determine if mouse is on the right side
			var is_right_side: bool = mouse_pos.x > 0
			
			# Set target x scale based on mouse position
			target_scale_x = -1 if is_right_side else 1
			
			# Calculate angle away from mouse position
			# We've already calculated the angle above, reuse it
			
			# Convert angle to degrees for display
			var angle_deg: float = rad_to_deg(mouse_pos.angle())
			# Normalize to 0-360 range
			if angle_deg < 0:
				angle_deg += 360.0
			# Emit signal with the angle in degrees
			angle_changed.emit(angle_deg)
			
			# Set target rotation based on which side the mouse is on
			if is_right_side:
				# Base rotation that makes sprite point away from the mouse
				target_rotation = mouse_pos.angle()
			else:
				# Normal rotation when on the left side
				target_rotation = mouse_pos.angle() + PI
	else:
		# When mouse is not held, set targets to return to original position
		target_rotation = 0.0
		target_scale_x = 1.0
		
		# Hide trajectory end sprite when not drawing
		if trajectory_end and trajectory_end.visible:
			trajectory_end.visible = false
		
		is_calculating_trajectory = false
	
	# Set target scale based on hover state
	if is_hovered or is_mouse_held:
		target_scale = hover_scale
	else:
		target_scale = base_scale
	
	# Apply smooth rotation and scaling
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, delta * rotation_speed)
	sprite.scale.x = lerp(sprite.scale.x, target_scale_x * target_scale.x, delta * rotation_speed)
	sprite.scale.y = lerp(sprite.scale.y, target_scale.y, delta * rotation_speed)

func update_trajectory_line() -> void:
	trajectory_line.clear_points()
	
	if trajectory_points.size() > 0:
		# Calculate the maximum distance the projectile will travel in 5 seconds
		# Based on debugging data, the actual distance is about 78% of the theoretical maximum
		var correction_factor = 0.78  # Empirically determined from debug logs
		var max_travel_distance = BASE_SPEED * speed_multiplier * 5.0 * correction_factor
		
		# Process trajectory points to find the endpoint based on distance
		var processed_points = calculate_trajectory_with_endpoint(trajectory_points, max_travel_distance)
		
		# Add all the calculated trajectory points to the Line2D
		for point in processed_points:
			trajectory_line.add_point(point)
		
		# Update trajectory end sprite position and visibility
		if trajectory_end:
			trajectory_end.visible = true
			# Use the last point as the end marker
			trajectory_end.position = processed_points[processed_points.size() - 1]

# Calculate the final trajectory with proper endpoint based on maximum travel distance
func calculate_trajectory_with_endpoint(points: Array[Vector2], max_distance: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var distance_traveled: float = 0.0
	
	result.append(points[0])
	
	# Process each segment to calculate distance
	for i in range(1, points.size()):
		var prev_point = points[i-1]
		var current_point = points[i]
		var segment_distance = prev_point.distance_to(current_point)
		
		# Check if adding this segment would exceed the max distance
		if distance_traveled + segment_distance > max_distance:
			# Calculate the partial segment that fits within the max distance
			var remaining_distance = max_distance - distance_traveled
			var direction = (current_point - prev_point).normalized()
			var endpoint = prev_point + direction * remaining_distance
			
			# Add the endpoint and stop processing
			result.append(endpoint)
			break
		
		# Add the current point and update distance traveled
		result.append(current_point)
		distance_traveled += segment_distance
		
	# If we processed all points without exceeding max distance, use the last point
	if result.size() < 2:
		result.append(points[1]) # At least add the second point for a valid line
	
	return result

func launch_projectile() -> void:
	if current_line_end.length() > 0:
		# Select the appropriate projectile scene based on GameManager state
		var projectile_scene = PullProjectileScene if GameManager.is_using_pull_projectile() else PushProjectileScene
		var projectile_container = projectile_scene.instantiate()
		
		get_parent().add_child(projectile_container)
		projectile_container.position = position
		
		# Wait one frame for the viewport to initialize properly
		await get_tree().process_frame
		
		projectile_container.projectile_destroyed.connect(_on_projectile_destroyed)
		var speed_multiplier: float = current_line_end.length() / MAX_LINE_LENGTH
		projectile_container.launch(current_line_end.normalized(), speed_multiplier)
		projectile_created.emit(projectile_container)
		increment_score()
		can_shoot = false
		
		update_charge_bar_requested.emit(0)

func _on_projectile_destroyed() -> void:
	if earth and earth.linear_velocity.length() <= earth.movement_threshold:
		# Earth is not moving significantly, enable shooting immediately
		can_shoot = true

func _on_earth_stopped_moving() -> void:
	can_shoot = true

func _on_victory_achieved() -> void:
	can_shoot = false
	
	# Release mouse capture if it was captured and drag started in area
	if drag_started_in_area and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().warp_mouse(stored_mouse_position)
		drag_started_in_area = false
	
	# Clear any active shooting UI
	if is_mouse_held:
		is_mouse_held = false
		line.clear_points()
		trajectory_line.clear_points()
		
		# Hide trajectory end sprite
		if trajectory_end:
			trajectory_end.visible = false

func increment_score() -> void:
	add_shot_requested.emit(1)

func _on_mouse_entered() -> void:
	is_hovered = true

func _on_mouse_exited() -> void:
	is_hovered = false

# Updates the visibility of push and pull overlays based on current projectile type
func update_projectile_overlays() -> void:
	push_overlay.visible = !GameManager.is_using_pull_projectile()
	pull_overlay.visible = GameManager.is_using_pull_projectile()

func _on_projectile_type_changed(_using_pull: bool) -> void:
	update_projectile_overlays()
