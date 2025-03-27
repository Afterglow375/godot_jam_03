extends CanvasLayer

var score: int = 0
var angle: float = 0.0

func _ready() -> void:
	update_score_display()
	update_angle_display()

# Update the score and display
func update_score(new_score: int) -> void:
	score = new_score
	update_score_display()

# Add points to the current score
func add_score(points: int) -> void:
	score += points
	update_score_display()

# Update the score label
func update_score_display() -> void:
	$MarginContainer/VBoxContainer/ScoreLabel.text = "Shots: " + str(score)

# Update the angle display
func update_angle(new_angle: float) -> void:
	angle = new_angle
	update_angle_display()

# Update the angle label
func update_angle_display() -> void:
	$MarginContainer/VBoxContainer/AngleLabel.text = "Angle: " + ("%.2f" % angle) 
