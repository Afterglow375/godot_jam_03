extends RigidBody2D

signal earth_stopped_moving

var was_moving: bool = false
var movement_threshold: float = 2.0  # Threshold to determine if Earth has stopped moving
var sprite: Sprite2D = null
var visual_angular_velocity: float = 0.0  # Simulated angular velocity for rotation
var angular_damping: float = 2.0  # How quickly angular velocity slows down
var angular_acceleration_factor: float = 0.15  # Reduced from 0.5 to make spinning slower
var damage_numbers: Node2D = null
var damage_label: Label = null
var sun: Area2D = null
var bonus_area: Area2D = null
var accuracy_score: int = 0
var bonus_points: int = 0
var fire_particles: GPUParticles2D = null
var original_process_material: ParticleProcessMaterial = null

func _ready():
	# Enable contact monitoring for collision detection
	contact_monitor = true
	max_contacts_reported = 1
	
	# Get the sprite node
	sprite = $Sprite2D
	
	# Disable physics rotation of the RigidBody2D
	can_sleep = false
	lock_rotation = true
	
	# Get reference to damage numbers node and its label
	damage_numbers = $DamageNumbers
	damage_label = damage_numbers.get_node("Label")
	
	# Get reference to fire particles
	fire_particles = $FireParticles
	original_process_material = fire_particles.process_material
	
	# Find sun and bonus area in the scene
	sun = get_node("../Sun")
	bonus_area = get_node("../Sun/BonusArea")
	
	# Connect to their signals
	sun.accuracy_score_changed.connect(_on_accuracy_score_changed)
	sun.body_entered.connect(_on_sun_body_entered)
	sun.body_exited.connect(_on_sun_body_exited)
	bonus_area.bonus_points_changed.connect(_on_bonus_points_changed)
	
	# Hide damage numbers initially
	damage_numbers.visible = false
	
	# Stop particles initially
	fire_particles.emitting = false

func _process(delta: float) -> void:
	var is_moving_bool: bool = is_moving()
	
	# Earth just started moving
	if is_moving_bool and not was_moving:
		was_moving = true
	
	# Earth just stopped moving
	elif not is_moving_bool and was_moving:
		earth_stopped_moving.emit()
		was_moving = false
	
	# Physics-like rotation simulation
	if sprite:
		# Calculate torque based on velocity and current orientation
		var torque: float = 0.0
		
		if is_moving_bool:
			# Use perpendicular component of velocity relative to current orientation to determine torque
			# This simulates the physical effect of forces not aligned with center of mass
			var perp_vel: float = linear_velocity.rotated(-global_rotation).y
			torque = perp_vel * angular_acceleration_factor
		
		# Apply angular acceleration (F = ma)
		visual_angular_velocity += torque * delta
		
		# Clamp the maximum angular velocity
		visual_angular_velocity = clamp(visual_angular_velocity, -1.5, 1.5)
		
		# Apply angular damping
		visual_angular_velocity *= (1.0 - delta * angular_damping)
		
		# Apply rotation to sprite
		sprite.rotation += visual_angular_velocity * delta
		
func _physics_process(delta):
	if linear_velocity.length() < 10.0:  # If speed is very low
		linear_velocity = Vector2.ZERO  # Force stop
		
func is_moving() -> bool:
	return linear_velocity.length() >= movement_threshold

# Function to get the collision radius of the Earth
func get_collision_radius() -> float:
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		return collision_shape.shape.radius
	return 0.0

func _on_body_entered(body):
	# Add a smaller impulse to angular velocity when collision happens (reduced from -2.0,2.0)
	visual_angular_velocity += randf_range(-0.8, 0.8)
	AudioManager.play(AudioManager.Audio.EARTH_WALL)

func _on_sun_body_entered(body: Node2D) -> void:
	if body == self:
		damage_numbers.show_with_animation()

func _on_sun_body_exited(body: Node2D) -> void:
	if body == self:
		damage_numbers.hide_with_animation()
		fire_particles.emitting = false
		fire_particles.amount_ratio = 0.05  # Reset to minimum

func _on_accuracy_score_changed(new_score: int) -> void:
	damage_numbers.update_accuracy_score(new_score)
	
	# Calculate ratio based on score (100-200 maps to 0.05-1.0)
	var ratio = 0.05 + (new_score - 100) * (0.95 / 100.0)
	
	# Start particles if not already emitting
	if !fire_particles.emitting:
		fire_particles.emitting = true
	
	# Set amount ratio (controls percentage of particles that emit)
	fire_particles.amount_ratio = ratio

func _on_bonus_points_changed(points: int) -> void:
	damage_numbers.update_bonus_points(points)

func update_damage_numbers() -> void:
	damage_label.text = str(accuracy_score + bonus_points)

