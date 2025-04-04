extends "res://scripts/entities/base_outer_projectile.gd"
# This script handles the push effect of the projectile, which pushes objects away from it

const PUSH_FORCE: float = 3000.0

# Explosion-specific variables
@export var explosion_force: float = 600.0  # Force applied to rigidbodies when detonating
@export var distance_multiplier: float = 1  # Force multiplier based on distance

# Override to implement push behavior - force away from the projectile
# Uses original force_multiplier where objects closer to center get more force
func get_force_direction(to_body: Vector2, force_multiplier: float, time_factor: float) -> Vector2:
	return to_body.normalized() * PUSH_FORCE * force_multiplier * time_factor

# Override to implement explosion push behavior
func apply_explosion_force() -> void:
	if not GameManager.is_paused():
		var inner_projectile_body = get_parent()
		
		for body_data in affected_bodies:
			var body = body_data[0]  # First element is the body
			var body_radius = body_data[1]  # Second element is the radius
			
			if body != inner_projectile_body:
				# Calculate the distance from the projectile center to the body
				var distance: float = global_position.distance_to(body.global_position)
				
				# Calculate force multiplier based on distance (normalized to 0.0-1.0 range)
				# Account for both force_radius and body_radius
				var normalized_distance: float = min(distance / (force_radius + body_radius), 1.0)
				
				# Apply inverse scaling - closer objects get more force (1.0 to 2.0)
				var force_scale: float = 1.0 + ((1.0 - normalized_distance) * distance_multiplier)
				
				# Push force - apply force away from the projectile with distance-based scaling
				var direction: Vector2 = (body.global_position - global_position).normalized()
				var scaled_force: float = explosion_force * force_scale
				
				body.apply_central_impulse(direction * scaled_force) 
