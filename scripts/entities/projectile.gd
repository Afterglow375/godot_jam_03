extends Area2D

var velocity: Vector2 = Vector2.ZERO
const BASE_SPEED: float = 2000.0
const PUSH_FORCE: float = 2000.0  # Base force value
const MIN_FORCE_MULTIPLIER: float = 0.2  # Minimum force at edge (20% of max force)

@export var force_radius: float = 100.0  # Radius where force starts falling off
@export var use_impulse: bool = true  # If true, applies impulse instead of continuous force
@export var lifetime: float = 5.0  # Time in seconds before projectile destroys itself

var affected_bodies: Array[RigidBody2D] = []
var time_alive: float = 0.0

func _ready():
	# Enable detection of bodies entering/exiting for the body_entered/exited signals
	monitoring = true

func _process(delta):
	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		destroy()

func _physics_process(delta):
	# Update projectile position
	position += velocity * delta
	
	# Process affected bodies
	for body in affected_bodies:
		# Calculate direction and distance from projectile to body
		var to_body: Vector2 = body.global_position - global_position
		var distance: float = to_body.length()
		
		# Scale force based on distance - closer objects get more force
		var force_multiplier: float = max(1.0 - (distance / force_radius), MIN_FORCE_MULTIPLIER)
		var force: Vector2 = to_body.normalized() * PUSH_FORCE * force_multiplier
		
		# Apply force or impulse based on setting
		if use_impulse:
			body.apply_central_impulse(force * delta)
		else:
			body.apply_central_force(force)

func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		affected_bodies.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		affected_bodies.erase(body)

func launch(direction: Vector2, speed_multiplier: float = 1.0) -> void:
	velocity = -direction * (BASE_SPEED * speed_multiplier)

# Call this to manually destroy the projectile
func destroy() -> void:
	queue_free()
