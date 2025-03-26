extends Area2D

const PUSH_FORCE: float = 4000.0
const FADE_DURATION: float = 0.1  # Fade in/out duration in seconds

# Using arrays of length 2 [body, radius] instead of dictionaries
var affected_bodies: Array = []
var force_radius: float = 100.0  # Default value, will be updated in _ready()
var push_sound_player: AudioStreamPlayer2D = null  # Persistent audio player

@onready var audio_manager = get_node("/root/AudioManager")
@onready var game_manager = get_node("/root/GameManager")

func _ready():
	# Enable detection of bodies entering/exiting for the body_entered/exited signals
	monitoring = true
	
	# Get the radius from the CollisionShape2D if it exists
	for child in get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			force_radius = child.shape.radius
			break
	
	# Connect to tree_exiting to clean up sound when scene changes
	tree_exiting.connect(_on_tree_exiting)

func _physics_process(delta):
	# Skip force application when game is paused
	if game_manager.is_paused():
		return
		
	# Process affected bodies
	for body_data in affected_bodies:
		var body: RigidBody2D = body_data[0]  # First element is the body
		var body_radius: float = body_data[1]  # Second element is the radius
		
		# Calculate direction and distance from projectile to body
		var to_body: Vector2 = body.global_position - global_position
		var distance: float = to_body.length()
		
		# Scale force based on distance - closer objects get more force
		var force_multiplier: float = 1.0 - (distance / (force_radius + body_radius))
		
		var force: Vector2 = to_body.normalized() * PUSH_FORCE * force_multiplier
		
		body.apply_central_force(force)

func _process(_delta):
	# Update the sound position to match the projectile's position
	if push_sound_player and is_instance_valid(push_sound_player):
		push_sound_player.global_position = global_position

func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var body_radius: float = 0.0
		
		# Try to get the collision radius using the get_collision_radius method
		if body.has_method("get_collision_radius"):
			body_radius = body.get_collision_radius()
		else:
			# Fallback to searching for the collision shape
			for child in body.get_children():
				if child is CollisionShape2D and child.shape is CircleShape2D:
					body_radius = child.shape.radius
					break
		
		# Store body and radius as a simple array of length 2
		affected_bodies.append([body, body_radius])
		
		push_sound_player = audio_manager.play_positional(
			AudioManager.Audio.EARTH_PUSH,
			global_position,
			false,
			false
		)
		
		# Fade in the sound
		push_sound_player.volume_db = -40.0  # Start very quiet
		
		# Create a tween for fading in
		var tween = create_tween()
		tween.tween_property(push_sound_player, "volume_db", -5.0, FADE_DURATION)
		
		# Start playing
		push_sound_player.play()

func _on_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		# Find and remove the body from affected_bodies
		for i in range(affected_bodies.size() - 1, -1, -1):
			if affected_bodies[i][0] == body:  # First element is the body
				affected_bodies.remove_at(i)
				break
		
		# If no more bodies are affected, fade out and stop the sound
		if affected_bodies.size() == 0 and push_sound_player and push_sound_player.playing:
			# Create a tween for fading out
			var tween = create_tween()
			tween.tween_property(push_sound_player, "volume_db", -40.0, FADE_DURATION)
			
			# Stop the player after fade completes
			tween.tween_callback(func(): push_sound_player.queue_free())

func _on_tree_exiting() -> void:
	# Clean up the sound player if it exists
	if push_sound_player and is_instance_valid(push_sound_player):
		push_sound_player.stop()
		push_sound_player.queue_free()
