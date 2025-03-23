extends RigidBody2D

signal projectile_destroyed
signal explosion_charged
signal charging_started(charge_time)
signal explosion_triggered(fade_time)

@onready var outer_projectile: Area2D = $"Outer Projectile"
@onready var sprites: Array[Sprite2D] = [$Sprite2D, $Sprite2D2]

# Get reference to the AudioManager singleton
@onready var audio_manager = get_node("/root/AudioManager")
@onready var GPUParticles: GPUParticles2D = $GPUParticles2D

const BASE_SPEED: float = 2000.0
@export var lifetime: float = 5.0  # Time in seconds before projectile destroys itself
@export var explosion_charge_time: float = 0.25  # Time to charge explosion
@export var explosion_force: float = 600.0  # Force applied to rigidbodies
@export var fade_duration: float = 0.15  # Duration of the fade-out animation

var time_alive: float = 0.0
var charging_explosion: bool = false
var charge_time: float = 0.0
var fading: bool = false
var fade_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Add to projectiles group for tracking
	add_to_group("projectiles")
	
	# Enable contact monitoring for collision detection
	contact_monitor = true
	max_contacts_reported = 1
	
	# Set initial charge amount
	set_charge_amount(0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Handle fade animation timing
	if fading:
		fade_time += delta
		
		# Map the fade time to shader values (0.95 to 1.0)
		var fade_progress: float = 0.95 + (fade_time / fade_duration) * 0.05
		fade_progress = min(fade_progress, 1.0)
		
		# Update shader fade parameter
		set_charge_amount(fade_progress)
		
		# When fade animation is complete, start the destroy sequence
		if fade_time >= fade_duration:
			destroy()
	
	# Only check for input when not already charging, fading, or destroying
	if not charging_explosion and not fading:
		# Check lifetime and destroy if expired
		time_alive += delta
		if time_alive >= lifetime:
			destroy()
		# Check for explosion trigger with direct mouse button check
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			start_charging_explosion()
	
	# Handle explosion charging
	if charging_explosion and not fading:
		charge_time += delta
		
		if !GPUParticles.is_playing():
			GPUParticles.play()
		
		# Calculate normalized charge progress (clamped between 0 and 1)
		var charge_progress: float = min(charge_time / explosion_charge_time, 0.95)  # Cap at 0.95 for shader
		
		# Update shader for charging effect
		set_charge_amount(charge_progress)
		
		if charge_time >= explosion_charge_time:
			trigger_explosion()
	
func set_charge_amount(value: float) -> void:
	for sprite in sprites:
		var charge_shader: ShaderMaterial = sprite.material
		if charge_shader:
			charge_shader.set_shader_parameter("charge_amount", value)

func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		# Play the wall collision sound
		audio_manager.play(audio_manager.Audio.PROJECTILE_WALL)

# Launch the projectile in the specified direction
func launch(direction: Vector2, speed_multiplier: float = 1.0) -> void:
	# Set the linear_velocity directly for RigidBody2D
	linear_velocity = -direction * (BASE_SPEED * speed_multiplier)
	
	# Play launch sound
	audio_manager.play(audio_manager.Audio.PROJECTILE_SHOT)

# Start the explosion charging sequence
func start_charging_explosion() -> void:
	charging_explosion = true
	charge_time = 0.0
	
	# Emit signal that charging has started with charge time duration
	charging_started.emit(explosion_charge_time)
	
	# Play the charge sound
	audio_manager.play(audio_manager.Audio.DETONATE_EXPLOSION_CHARGE)

# Trigger the actual explosion but start the fade effect before destroying
func trigger_explosion() -> void:
	# Signal that explosion is fully charged
	explosion_charged.emit()
	
	# Emit signal that explosion was triggered with fade duration
	explosion_triggered.emit(fade_duration)
	
	# Play explosion sound
	audio_manager.play(audio_manager.Audio.DETONATE_EXPLOSION)
	
	# Stop the projectile's movement
	linear_velocity = Vector2.ZERO
	freeze = true  # Freeze the RigidBody2D
	
	# Apply force to all rigidbodies in the outer projectile area
	var bodies = outer_projectile.get_overlapping_bodies()
	for body in bodies:
		if body is RigidBody2D and body != self:
			var direction = (body.global_position - global_position).normalized()
			body.apply_central_impulse(direction * explosion_force)
	
	# Stop charging and start fading
	charging_explosion = false
	fading = true
	fade_time = 0.0

# Call this to immediately destroy the projectile
func destroy() -> void:
	projectile_destroyed.emit()
	queue_free()
