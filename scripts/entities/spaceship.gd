extends Area2D

const MAX_LINE_LENGTH: float = 500.0  # Adjust this value to change max length
const ProjectileScene: PackedScene = preload("res://scenes/entities/projectile.tscn")

var is_mouse_held: bool = false
var line: Line2D
var current_line_end: Vector2 = Vector2.ZERO
var drag_started_in_area: bool = false

func _ready():
	line = $Line2D
	line.clear_points()
	
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drag_started_in_area = true
			is_mouse_held = true

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if drag_started_in_area:  # Only launch if drag started in area
				launch_projectile()
				drag_started_in_area = false
			is_mouse_held = false
			line.clear_points()

func _process(delta):
	if is_mouse_held:
		var mouse_pos: Vector2 = get_local_mouse_position()
		var length: float = mouse_pos.length()
		
		# Draw the line with clamped length if needed
		current_line_end = mouse_pos
		if length > MAX_LINE_LENGTH:
			current_line_end = mouse_pos.normalized() * MAX_LINE_LENGTH
		
		line.clear_points()
		line.add_point(Vector2.ZERO)  # Center of the Area2D
		line.add_point(current_line_end)  # Clamped position for line

func launch_projectile() -> void:
	if current_line_end.length() > 0:
		var projectile: Node = ProjectileScene.instantiate()
		get_parent().add_child(projectile)
		projectile.position = position
		
		# Calculate speed multiplier based on line length (0.0 to 1.0)
		var speed_multiplier: float = current_line_end.length() / MAX_LINE_LENGTH
		
		# Launch in the direction of the line with speed based on length
		projectile.launch(current_line_end.normalized(), speed_multiplier)
