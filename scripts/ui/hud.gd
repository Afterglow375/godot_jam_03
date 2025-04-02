extends CanvasLayer


func _ready() -> void:
	update_shots_display(0)
	update_angle_display(0.0)
	var spaceship = get_node("../../Spaceship")
	spaceship.angle_changed.connect(_on_spaceship_angle_changed)
	
# Handle angle changed signal from spaceship
func _on_spaceship_angle_changed(new_angle: float) -> void:
	update_angle_display(new_angle)

# Update the shots label
func update_shots_display(num_shots: int = 0) -> void:
	$MarginContainer/VBoxContainer/ScoreLabel.text = "Shots: " + str(num_shots)

# Update the angle label
func update_angle_display(angle: float) -> void:
	$MarginContainer/VBoxContainer/AngleLabel.text = "Angle: " + ("%.2f" % angle) 
