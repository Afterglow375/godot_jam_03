extends Area2D

const PUSH_FORCE: float = 4000.0

@export var lifetime: float = 5.0  # Time in seconds before projectile destroys itself

# Using arrays of length 2 [body, radius] instead of dictionaries
var affected_bodies: Array = []
var time_alive: float = 0.0
var force_radius: float = 100.0  # Default value, will be updated in _ready()

func _ready():
	# Enable detection of bodies entering/exiting for the body_entered/exited signals
	monitoring = true
	
	# Get the radius from the CollisionShape2D if it exists
	for child in get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			force_radius = child.shape.radius
			break

func _process(delta):
	time_alive += delta
	if time_alive >= lifetime:
		destroy()

func _physics_process(delta):
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

func _on_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		# Find and remove the body from affected_bodies
		for i in range(affected_bodies.size() - 1, -1, -1):
			if affected_bodies[i][0] == body:  # First element is the body
				affected_bodies.remove_at(i)
				break

# Call this to manually destroy the projectile
func destroy() -> void:
	# Get the parent (inner projectile) and destroy it
	# This will also destroy this node as it's a child
	get_parent().queue_free()
