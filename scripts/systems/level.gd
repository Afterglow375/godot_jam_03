extends Node

var hud_scene = preload("res://scenes/ui/HUD.tscn")
var win_popup_scene = preload("res://scenes/ui/win_popup.tscn")
var hud: CanvasLayer = null
var win_popup: CanvasLayer = null
var score: int = 0
var accuracy_score: int = 0
var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var pause_menu: CanvasLayer = null
var is_paused: bool = false
var level_finished: bool = false

func _ready() -> void:
	add_hud()
	add_pause_menu()
	add_win_popup()
	
	# Add listeners for win_popup signals
	win_popup.next_level.connect(_on_next_level)
	win_popup.retry_level.connect(_on_retry_level)
	
	# Hide pause menu initially
	if pause_menu != null:
		pause_menu.visible = false
	
	# Set process input to work even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Check for the R key press to reset the level/score
		if event.keycode == KEY_R:
			reset_score()
			reset_level()
		# Check for Escape key press to toggle pause menu
		elif event.keycode == KEY_ESCAPE and not level_finished:
			toggle_pause_menu()

# Toggle the pause menu visibility and level pause state
func toggle_pause_menu() -> void:
	is_paused = !is_paused
	
	if pause_menu != null:
		pause_menu.visible = is_paused
	
	# Pause/unpause the level
	get_tree().paused = is_paused
	
# Reload the current level
func reset_level() -> void:
	get_tree().change_scene_to_file(scene_file_path)

# Add the HUD to this level
func add_hud() -> void:
	hud = hud_scene.instantiate()
	add_child(hud)
	
# Add the win popup to this level
func add_win_popup() -> void:
	win_popup = win_popup_scene.instantiate()
	add_child(win_popup)

# Add the pause menu to this level
func add_pause_menu() -> void:
	pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)

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
	return final_score
	
func level_won() -> void:
	level_finished = true
	
	# If paused, unpause the level first
	if is_paused:
		toggle_pause_menu()
		
	win_popup.set_scores(score, accuracy_score)
	win_popup.show()

func _on_next_level():
	pass # implementing this soon

func _on_retry_level() -> void:
	reset_level()
