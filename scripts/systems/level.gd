extends Node

var hud_scene = preload("res://scenes/ui/HUD.tscn")
var win_popup_scene = preload("res://scenes/ui/win_popup.tscn")
var hud: CanvasLayer = null
var win_popup: CanvasLayer = null
var score: int = 0
var accuracy_score: int = 0

func _ready() -> void:
	# Add the HUD to this level
	add_hud()
	add_win_popup()
	
	# Add listeners for win_popup signals
	win_popup.next_level.connect(_on_next_level)
	win_popup.retry_level.connect(_on_retry_level)
	
func _input(event: InputEvent) -> void:
	# Check for the R key press to reset the level/score
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reset_score()
		reset_level()

# Reset the current level
func reset_level() -> void:
	# Reload the current level
	get_tree().change_scene_to_file(scene_file_path)

# Add the HUD to this level
func add_hud() -> void:
	# Check if HUD already exists
	if hud != null:
		return
		
	# Instance the HUD scene
	hud = hud_scene.instantiate()
	add_child(hud)
	
# Add the HUD to this level
func add_win_popup() -> void:
	# Check if already exists
	if win_popup != null:
		return
		
	# Instance the HUD scene
	win_popup = win_popup_scene.instantiate()
	add_child(win_popup)

# Update the score and display
func update_score(new_score: int) -> void:
	score = new_score
	update_score_display()

# Add points to the current score
func add_score(points: int) -> void:
	score += points
	update_score_display()

# Reset the score to zero
func reset_score() -> void:
	score = 0
	update_score_display()

# Update the score label
func update_score_display() -> void:
	if hud != null:
		hud.get_node("ScoreLabel").text = str(score)

# Calculate the final score based on number of shots and accuracy
func calculate_final_score(accuracy_score: int) -> int:
	self.accuracy_score = accuracy_score
	var final_score = round(accuracy_score / score)
	print(final_score)
	return final_score
	
func game_won():
	win_popup.set_scores(score, accuracy_score)
	win_popup.show()

func _on_next_level():
	pass # implementing this soon

func _on_retry_level():
	reset_level()
