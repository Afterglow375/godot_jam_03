extends Node

var num_shots: int = 0
var accuracy_score: int = 0
var level_finished: bool = false
var bonus_points: int = 0
var total_score: int = 0
var par_penalty: int = 0

@onready var hud = $UI/HUD
@onready var charge_bar = $UI/HUD/MarginContainer/VBoxContainer/MarginContainer/ChargeBar
@onready var pause_menu = $UI/PauseMenu
@onready var win_popup = $UI/WinPopup

func _ready() -> void:
	# Add listeners for win_popup signals
	win_popup.next_level.connect(_on_next_level)
	win_popup.retry_level.connect(_on_retry_level)
	
	# Set process input to work even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Deferred to ensure nodes are ready
	call_deferred("connect_signals")

	var level_number: int = get_current_level_number()
	update_level_labels(level_number)

# Connect signals once the level is fully set up
func connect_signals() -> void:
	# Find and connect to bonus area signals
	var bonus_area: Area2D = find_child("BonusArea", true)
	bonus_area.bonus_points_changed.connect(_on_bonus_points_changed)
	
	# Find and connect to spaceship signals
	var spaceship: Area2D = find_child("Spaceship", true)
	spaceship.update_charge_bar_requested.connect(update_charge_bar)
	spaceship.add_shot_requested.connect(add_num_shots)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and not GameManager.is_paused():
			reset_level()
		elif event.keycode == KEY_ESCAPE and not level_finished:
			toggle_pause_menu()

# Toggle pause state and pause menu visibility
func toggle_pause_menu() -> void:
	GameManager.toggle_pause()
	pause_menu.visible = GameManager.is_paused()

# Reload the current level
func reset_level() -> void:
	reset_num_shots()
	SceneManager.reload_scene()

# Update the num_shots count and display
func update_num_shots(new_num_shots: int) -> void:
	num_shots = new_num_shots
	update_num_shots_display()

# Add num_shots to the current count
func add_num_shots(points: int) -> void:
	num_shots += points
	update_num_shots_display()

# Reset the num_shots count to zero
func reset_num_shots() -> void:
	num_shots = 0
	bonus_points = 0
	update_num_shots_display()

# Update the num_shots label
func update_num_shots_display() -> void:
	hud.update_shots_display(num_shots)

func update_charge_bar(new_value: float) -> void:
	charge_bar.value = new_value

# Calculate the final score based on number of shots and accuracy
func calculate_final_score(accuracy_score: int) -> int:
	self.accuracy_score = accuracy_score
	var base_score = accuracy_score + bonus_points
	var par = get_current_level_par()
	var shots_over_par = max(0, num_shots - par)
	par_penalty = shots_over_par * 25
	total_score = max(0, base_score - par_penalty)

	return total_score
	
func level_won() -> void:
	if level_finished:
		return
		
	level_finished = true
	calculate_final_score(accuracy_score)
	AudioManager.play(AudioManager.Audio.TADAA)
	
	# If paused, unpause the level first
	if GameManager.is_paused():
		toggle_pause_menu()
		
	# Wait a short moment to ensure bonus points are calculated
	await get_tree().create_timer(0.1).timeout
	win_popup.show_victory_screen(num_shots, accuracy_score, bonus_points, total_score, par_penalty)

func _on_next_level():
	var next_level_path = get_next_level_path()
	SceneManager.change_scene(next_level_path)

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

func show_win_popup() -> void:
	win_popup.show_victory_screen(num_shots, accuracy_score, bonus_points)
	win_popup.show()

func _on_bonus_points_changed(points: int) -> void:
	bonus_points = points

func update_level_labels(level_number: int) -> void:
	var level_label: Label = $UI/HUD/LevelContainer/VBoxContainer/LevelLabel
	var par_label: Label = $UI/HUD/LevelContainer/VBoxContainer/ParLabel
		
	level_label.text = "Level " + str(level_number)
	par_label.text = "Par " + str(get_current_level_par())
		
	# Also update the win popup label
	var win_label: Label = $UI/WinPopup/Panel/VBoxContainer/Label
	win_label.text = "Level " + str(level_number) + " Cleared!"

# Helper function to get the current level number from scene path
func get_current_level_number() -> int:
	var current_scene_path: String = get_tree().current_scene.scene_file_path
	var level_number: int = 0
	
	if "level_" in current_scene_path:
		var parts: Array = current_scene_path.get_file().replace(".tscn", "").split("_")
		if parts.size() > 1:
			level_number = parts[1].to_int()
	
	return level_number

# Get the par for the current level
func get_current_level_par() -> int:
	var level_number = get_current_level_number()
	return GameManager.LEVEL_PARS.get(level_number, 0)  # Return 0 if level number not found
