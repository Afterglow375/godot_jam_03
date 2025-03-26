extends Node

var hud_scene = preload("res://scenes/ui/HUD.tscn")
var win_popup_scene = preload("res://scenes/ui/win_popup.tscn")
var hud: CanvasLayer = null
var win_popup: CanvasLayer = null
var score: int = 0
var accuracy_score: int = 0
var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var pause_menu: CanvasLayer = null
var level_finished: bool = false
var charge_bar: ProgressBar = null
var bonus_points: int = 0

# Get reference to the AudioManager singleton
@onready var audio_manager = get_node("/root/AudioManager")
# Get reference to the GameManager singleton
@onready var game_manager = get_node("/root/GameManager")

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
		# Check for the R key press to reset the level/score (only when not paused)
		if event.keycode == KEY_R and not game_manager.is_paused():
			reset_score()
			reset_level()
		# Check for Escape key press to toggle pause menu
		elif event.keycode == KEY_ESCAPE and not level_finished:
			toggle_pause_menu()

# Toggle the pause menu visibility and level pause state
func toggle_pause_menu() -> void:
	game_manager.toggle_pause()
	
	if pause_menu != null:
		pause_menu.visible = game_manager.is_paused()

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

# Add bonus points (separate from regular score)
func add_bonus_points(points: int) -> void:
	bonus_points = points

# Reset the score to zero
func reset_score() -> void:
	score = 0
	bonus_points = 0
	update_score_display()

# Update the score label
func update_score_display() -> void:
	if hud != null:
		hud.get_node("ScoreLabel").text = str(score)

func update_charge_bar(new_value) -> void:
	if charge_bar == null and hud != null:
		charge_bar = hud.get_node("ChargeBar")
	
	if charge_bar:
		charge_bar.value = new_value

# Calculate the final score based on number of shots and accuracy
func calculate_final_score(accuracy_score: int) -> int:
	self.accuracy_score = accuracy_score
	var final_score = round(accuracy_score / score)
	return final_score
	
func level_won() -> void:
	if level_finished:
		return
		
	level_finished = true
	calculate_final_score(accuracy_score)
	audio_manager.play(audio_manager.Audio.TADAA)
	
	# If paused, unpause the level first
	if game_manager.is_paused():
		toggle_pause_menu()
		
	# Wait a short moment to ensure bonus points are calculated
	await get_tree().create_timer(0.1).timeout
	win_popup.show_victory_screen(score, accuracy_score, bonus_points)

func _on_next_level():
	var next_level_path = get_next_level_path()
	get_tree().change_scene_to_file(next_level_path)

func _on_retry_level() -> void:
	reset_level()

func get_next_level_path() -> String:
	var current_scene_path = get_tree().current_scene.scene_file_path
	if "level_" in current_scene_path:
		var parts = current_scene_path.get_file().replace(".tscn", "").split("_")
		if parts.size() > 1:
			var level_number = parts[1].to_int()  # Extract number
			var next_level_number = level_number + 1
			var next_level_path = "res://scenes/levels/level_" + str(next_level_number) + ".tscn"

			if ResourceLoader.exists(next_level_path):  # Ensure file exists
				return next_level_path

	return ""  # No next level found

# Show win popup
func show_win_popup() -> void:
	if win_popup != null:
		win_popup.show_victory_screen(score, accuracy_score, bonus_points)
		win_popup.show()
