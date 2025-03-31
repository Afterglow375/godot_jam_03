extends Node

var hud_scene = preload("res://scenes/ui/HUD.tscn")
var win_popup_scene = preload("res://scenes/ui/win_popup.tscn")
var hud: CanvasLayer = null
var win_popup: CanvasLayer = null
var shots: int = 0
var accuracy_score: int = 0
var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var pause_menu: CanvasLayer = null
var level_finished: bool = false
var charge_bar: ProgressBar = null
var spaceship: Area2D = null
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
	
	# Connect to spaceship signals (deferred to ensure nodes are ready)
	call_deferred("connect_signals")

# Connect signals once the level is fully set up
func connect_signals() -> void:
	# Find spaceship in the scene
	spaceship = find_child("Spaceship", true)
	spaceship.angle_changed.connect(_on_spaceship_angle_changed)
		
	# Find and connect to bonus area signals
	var bonus_area: Area2D = find_child("BonusArea", true)
	bonus_area.bonus_points_changed.connect(_on_bonus_points_changed)

# Handle angle changed signal from spaceship
func _on_spaceship_angle_changed(new_angle: float) -> void:
	hud.update_angle(new_angle)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Check for the R key press to reset the level/score (only when not paused)
		if event.keycode == KEY_R and not game_manager.is_paused():
			reset_shots()
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
	# Get the absolute path to the current scene
	var current_scene_path = scene_file_path
	# The GameManager will automatically maintain which projectile type we're using
	get_tree().change_scene_to_file(current_scene_path)

# Add the HUD to this level
func add_hud() -> void:
	hud = hud_scene.instantiate()
	add_child(hud)
	# Initialize charge_bar reference
	call_deferred("_setup_charge_bar")
	
# Setup charge bar reference after HUD is added to scene tree
func _setup_charge_bar() -> void:
	charge_bar = hud.get_node("MarginContainer/VBoxContainer/MarginContainer/ChargeBar")

# Add the win popup to this level
func add_win_popup() -> void:
	win_popup = win_popup_scene.instantiate()
	add_child(win_popup)

# Add the pause menu to this level
func add_pause_menu() -> void:
	pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)

# Update the shots count and display
func update_shots(new_shots: int) -> void:
	shots = new_shots
	update_shots_display()

# Add shots to the current count
func add_shots(points: int) -> void:
	shots += points
	update_shots_display()

# Reset the shots count to zero
func reset_shots() -> void:
	shots = 0
	bonus_points = 0
	update_shots_display()

# Update the shots label
func update_shots_display() -> void:
	hud.update_shots(shots)

func update_charge_bar(new_value) -> void:
	charge_bar.value = new_value

# Calculate the final score based on number of shots and accuracy
func calculate_final_score(accuracy_score: int) -> int:
	self.accuracy_score = accuracy_score
	var final_score = round(accuracy_score / shots)
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
	win_popup.show_victory_screen(shots, accuracy_score, bonus_points)

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
		win_popup.show_victory_screen(shots, accuracy_score, bonus_points)
		win_popup.show()

# Handle bonus points changed signal
func _on_bonus_points_changed(points: int) -> void:
	bonus_points = points
