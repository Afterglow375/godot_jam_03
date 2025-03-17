extends Node

var hud_scene = preload("res://scenes/ui/HUD.tscn")
var hud: CanvasLayer = null
var score: int = 0

func _ready() -> void:
	# Add the HUD to this level
	add_hud()
	
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
