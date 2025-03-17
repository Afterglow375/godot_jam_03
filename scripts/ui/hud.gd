extends CanvasLayer

var score: int = 0

func _ready() -> void:
	update_score_display()

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
	$ScoreLabel.text = str(score) 
