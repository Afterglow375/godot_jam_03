extends "res://scripts/entities/base_outer_projectile.gd"
# This script handles the pull effect of the projectile, which pulls objects towards it
# It's a variation of the push projectile, with reversed force direction

const PULL_FORCE: float = 3000.0

# Explosion-specific variables
@export var explosion_force: float = 600.0  # Base force applied to rigidbodies when detonating
@export var distance_multiplier: float = 1  # Force multiplier based on distance

# Override to implement pull behavior - force towards the projectile
# Inverts the force_multiplier so objects farther away get pulled harder
func get_force_direction(to_body: Vector2, force_multiplier: float) -> Vector2:
	# Invert the multiplier (1.0 becomes 0.0, 0.0 becomes 1.0)
	var inverted_multiplier: float = 1.0 - force_multiplier
	return -to_body.normalized() * PULL_FORCE * inverted_multiplier

# Override to implement explosion pull behavior
func apply_explosion_force() -> void:
	if not game_manager.is_paused():
		var inner_projectile_body = get_parent()
		
		for body_data in affected_bodies:
			var body = body_data[0]
			var body_radius = body_data[1]
			
			if body != inner_projectile_body:
				# Calculate the distance from the projectile center to the body
				var distance: float = global_position.distance_to(body.global_position)
				
				# Calculate force multiplier based on distance (normalized to 0.0-1.0 range)
				# Account for both force_radius and body_radius
				var normalized_distance: float = min(distance / (force_radius + body_radius), 1.0)
				
				# Apply a non-linear scaling to make the effect more pronounced
				var force_scale: float = 1.0 + (normalized_distance * distance_multiplier)
				
				# Pull force - apply force towards the projectile with distance-based scaling
				var direction: Vector2 = (global_position - body.global_position).normalized()
				var scaled_force: float = explosion_force * force_scale
				
				body.apply_central_impulse(direction * scaled_force) 
