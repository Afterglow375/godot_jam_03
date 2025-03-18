extends RigidBody2D

@onready var wall_collision_sound: AudioStreamPlayer = $WallCollision

const BASE_SPEED: float = 2000.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Enable contact monitoring for collision detection
	contact_monitor = true
	max_contacts_reported = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_body_entered(body):
	if body is StaticBody2D and not wall_collision_sound.playing:
		wall_collision_sound.play()

# Launch the projectile in the specified direction
func launch(direction: Vector2, speed_multiplier: float = 1.0) -> void:
	# Set the linear_velocity directly for RigidBody2D
	linear_velocity = -direction * (BASE_SPEED * speed_multiplier)

# Call this to manually destroy the projectile
func destroy() -> void:
	queue_free()
