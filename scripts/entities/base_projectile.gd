extends Node2D
# Base class for projectile containers with shared functionality

# Signals
signal projectile_destroyed
signal explosion_charged
signal charging_started(charge_time: float)
signal explosion_triggered(fade_time: float)

# Node references
@onready var inner_projectile: RigidBody2D = $"Inner Projectile"
@onready var texture_rect: TextureRect = $TextureRect
@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var outer_projectile: Area2D = $"Inner Projectile/Outer Projectile"
var projectile_sound_player: AudioStreamPlayer2D = null  # Persistent audio player

# Constants and export variables
const BASE_SPEED: float = 2000.0
@export var lifetime: float = 5.0  # Time in seconds before projectile destroys itself
@export var explosion_charge_time: float = 0.25  # Time to charge explosion
@export var fade_duration: float = 0.15  # Duration of the fade-out animation
var viewport_size: Vector2 = Vector2(800, 800)  # Explicitly track viewport size

# State variables
var time_alive: float = 0.0
var charging_explosion: bool = false
var charge_time: float = 0.0
var fading: bool = false
var fade_time: float = 0.0
var initial_position: Vector2 = Vector2.ZERO  # Store initial position for distance calculation
var total_distance_traveled: float = 0.0  # Track total distance traveled
var last_position: Vector2 = Vector2.ZERO  # Track last position for distance calculation

func _ready() -> void:
	# Setup the inner projectile (RigidBody2D)
	inner_projectile.contact_monitor = true
	inner_projectile.max_contacts_reported = 1
	
	# Connect inner projectile's body_entered signal
	inner_projectile.body_entered.connect(_on_body_entered)
	
	# Connect to tree_exiting to clean up sound when scene changes
	tree_exiting.connect(_on_tree_exiting)
	
	# Connect to the outer projectile's signals
	outer_projectile.force_weakening.connect(_on_force_weakening)
	outer_projectile.force_fade_out.connect(_on_force_fade_out)
	
	# Set initial charge/white fade amount
	set_charge_amount(0.0)
	set_white_fade_amount(0.0)
	
	# Create the positional sound player
	create_projectile_sound_player()
	
	# Store initial position
	initial_position = global_position
	last_position = global_position

func _process(delta: float) -> void:
	# Get the position of the Inner Projectile
	var projectile_pos: Vector2 = inner_projectile.global_position
	
	# Update distance tracking
	total_distance_traveled += last_position.distance_to(projectile_pos)
	last_position = projectile_pos
	
	# Center the TextureRect/SubViewportContainer on the projectile
	texture_rect.global_position = projectile_pos - viewport_size/2
	viewport_container.global_position = projectile_pos - viewport_size/2
	
	# Update the sound position to match the outer projectile's position
	if projectile_sound_player and is_instance_valid(projectile_sound_player):
		projectile_sound_player.global_position = outer_projectile.global_position
	
	# Handle fade animation timing
	if fading:
		fade_time += delta
		
		# Map the fade time to shader values (0.95 to 1.0)
		var fade_progress: float = 0.95 + (fade_time / fade_duration) * 0.05
		fade_progress = min(fade_progress, 1.0)
		
		# Update shader fade parameter
		set_charge_amount(fade_progress)
		
		# When fade animation is complete, destroy container
		if fade_time >= fade_duration:
			destroy()
	
	# Only check for input when not already charging, fading, or destroying AND game is not paused
	if not charging_explosion and not fading and not GameManager.is_paused():
		# Check lifetime and destroy if expired
		time_alive += delta
		if time_alive >= lifetime:
			# Freeze projectile position when fizzling out
			inner_projectile.linear_velocity = Vector2.ZERO
			inner_projectile.freeze = true
			
			# Play fizzle sound
			play_fizzle_sound()
			
			# Start fading
			fading = true
			fade_time = 0.0
		# Check for explosion trigger with direct mouse button check
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			start_charging_explosion()
	
	# Handle explosion charging - only continue if game is not paused
	if charging_explosion and not fading and not GameManager.is_paused():
		charge_time += delta
		
		# Calculate normalized charge progress (clamped between 0 and 1)
		var charge_progress: float = min(charge_time / explosion_charge_time, 0.95)  # Cap at 0.95 for shader
		
		# Update shader charge amount
		set_charge_amount(charge_progress)
		
		# If white_fade_amount is active, reduce it to 0
		var current_white_fade = texture_rect.material.get_shader_parameter("white_fade_amount")
		if current_white_fade > 0.0:
			var white_fade_reduction = (delta / (explosion_charge_time)) * current_white_fade
			var new_white_fade = max(current_white_fade - white_fade_reduction, 0.0)
			set_white_fade_amount(new_white_fade)
		
		if charge_time >= explosion_charge_time:
			trigger_explosion()

func set_charge_amount(amount: float) -> void:
	texture_rect.material.set_shader_parameter("charge_amount", amount)

func set_white_fade_amount(amount: float) -> void:
	texture_rect.material.set_shader_parameter("white_fade_amount", amount)

func _on_force_weakening(time_factor: float) -> void:
	if not charging_explosion and not fading:
		set_white_fade_amount(time_factor)

func _on_force_fade_out() -> void:
	if not charging_explosion and not fading:
		var current_white_fade = texture_rect.material.get_shader_parameter("white_fade_amount")
		if current_white_fade > 0.0:
			var tween = create_tween()
			tween.tween_method(set_white_fade_amount, current_white_fade, 0.0, 0.25)

# Launch the projectile in the specified direction
func launch(direction: Vector2, speed_multiplier: float = 1.0) -> void:
	total_distance_traveled = 0.0
	last_position = global_position
	
	# Set the linear_velocity directly for RigidBody2D
	inner_projectile.linear_velocity = -direction * (BASE_SPEED * speed_multiplier)
	
	play_launch_sound()

func start_charging_explosion() -> void:
	charging_explosion = true
	charge_time = 0.0
	charging_started.emit(explosion_charge_time)
	play_charge_sound()

func trigger_explosion() -> void:
	explosion_charged.emit()
	
	explosion_triggered.emit(fade_duration)
	
	play_detonate_sound()
	
	inner_projectile.linear_velocity = Vector2.ZERO
	inner_projectile.freeze = true
	
	# Stop charging and start fading
	charging_explosion = false
	fading = true
	fade_time = 0.0

# Handle collision with bodies
func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		play_wall_collision_sound()

# Destroy the projectile and clean up resources
func destroy() -> void:
	if projectile_sound_player and is_instance_valid(projectile_sound_player):
		projectile_sound_player.queue_free()
	projectile_destroyed.emit()
	queue_free()

func _on_tree_exiting() -> void:
	# Clean up the sound player if it exists
	if projectile_sound_player and is_instance_valid(projectile_sound_player):
		projectile_sound_player.stop()
		projectile_sound_player.queue_free()

# Virtual method to be overridden by child classes - create projectile sound player
func create_projectile_sound_player() -> void:
	assert(false, "Method 'create_projectile_sound_player()' must be overridden in a subclass")

# Virtual method to be overridden by child classes - play launch sound
func play_launch_sound() -> void:
	assert(false, "Method 'play_launch_sound()' must be overridden in a subclass")

# Virtual method to be overridden by child classes - play charge sound
func play_charge_sound() -> void:
	assert(false, "Method 'play_charge_sound()' must be overridden in a subclass")

# Virtual method to be overridden by child classes - play detonate sound
func play_detonate_sound() -> void:
	assert(false, "Method 'play_detonate_sound()' must be overridden in a subclass")

# Virtual method to be overridden by child classes - play fizzle sound
func play_fizzle_sound() -> void:
	assert(false, "Method 'play_fizzle_sound()' must be overridden in a subclass")

# Virtual method to be overridden by child classes - play wall collision sound
func play_wall_collision_sound() -> void:
	assert(false, "Method 'play_wall_collision_sound()' must be overridden in a subclass")
