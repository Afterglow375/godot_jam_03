extends Area2D

signal bonus_points_changed(points: int)

var earth: RigidBody2D = null
var bonus_area_radius: float = 0.0
var earth_radius: float = 0.0
var max_bonus_points: int = 100
var has_awarded_bonus: bool = false
var movement_threshold: float = 2  # Threshold to determine if Earth has stopped moving

func _ready() -> void:
	# Get Earth's radius from its collision shape
	earth = get_node("/root/Main/Earth")
	var earth_collision_shape = earth.get_node("CollisionShape2D")
	earth_radius = earth_collision_shape.shape.radius
	
	# Get bonus area radius from its collision shape
	var collision_shape = get_node("CollisionShape2D")
	bonus_area_radius = collision_shape.shape.radius

func _process(_delta: float) -> void:
	if has_overlapping_bodies():
		# Check if Earth has stopped moving
		var overlap_ratio = calculate_overlap()
		if overlap_ratio > 0:
			var bonus_points = int(overlap_ratio * max_bonus_points)
			if bonus_points > 0:
				# Emit signal when bonus points are awarded
				bonus_points_changed.emit(bonus_points)

func calculate_overlap() -> float:
	if earth == null or bonus_area_radius <= 0 or earth_radius <= 0:
		return 0.0
		
	var distance = earth.global_position.distance_to(global_position)
	
	# If Earth is completely inside bonus area
	if distance + earth_radius <= bonus_area_radius:
		return 1.0
		
	# If bonus area is completely inside Earth
	if distance + bonus_area_radius <= earth_radius:
		return (bonus_area_radius * bonus_area_radius) / (earth_radius * earth_radius)
		
	# If circles don't overlap
	if distance >= earth_radius + bonus_area_radius:
		return 0.0
		
	# Calculate overlap area for partial intersection
	var overlap_area = 0.0
	var d = distance
	var r1 = earth_radius
	var r2 = bonus_area_radius
	
	# Formula for circle intersection area
	overlap_area = r1 * r1 * acos((d * d + r1 * r1 - r2 * r2) / (2 * d * r1)) + \
				   r2 * r2 * acos((d * d + r2 * r2 - r1 * r1) / (2 * d * r2)) - \
				   0.5 * sqrt((-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2))
	
	# Calculate ratio of overlap to Earth's area
	var earth_area = PI * earth_radius * earth_radius
	return overlap_area / earth_area 
