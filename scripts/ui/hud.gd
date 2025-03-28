extends CanvasLayer

var shots: int = 0
var angle: float = 0.0

func _ready() -> void:
	update_shots_display()
	update_angle_display()

# Update the shots count and display
func update_shots(new_shots: int) -> void:
	shots = new_shots
	update_shots_display()

# Add shots to the current count
func add_shots(points: int) -> void:
	shots += points
	update_shots_display()

# Update the shots label
func update_shots_display() -> void:
	$MarginContainer/VBoxContainer/ScoreLabel.text = "Shots: " + str(shots)

# Update the angle display
func update_angle(new_angle: float) -> void:
	angle = new_angle
	update_angle_display()

# Update the angle label
func update_angle_display() -> void:
	$MarginContainer/VBoxContainer/AngleLabel.text = "Angle: " + ("%.2f" % angle) 
