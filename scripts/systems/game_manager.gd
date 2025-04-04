extends Node

# This is a minimal GameManager that can be expanded for game-wide functionality
# such as saving/loading, global settings, etc.

# Global game state variables
var is_game_paused: bool = false
var using_pull_projectile: bool = false  # Track which projectile type is currently selected
var high_scores: Dictionary = {}  # Store high scores for each level

# Game state signals
signal game_paused(is_paused)
signal projectile_type_changed(using_pull: bool)  # Signal for projectile type changes

# Settings file path
const SETTINGS_FILE: String = "user://settings.cfg"
const HIGHSCORES_FILE: String = "user://highscores.cfg"

# Level number : par for that level
const LEVEL_PARS = {
	1: 1,
	2: 2,
	3: 1,
	4: 2,
	5: 2,
	6: 3,
	7: 2,
	8: 2,
	9: 1,
	10: 1,
	11: 3,
}

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Set process mode to always so the manager works even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("GameManager initialized")
	load_settings()
	load_high_scores()

# Set the pause state of the game
func set_pause_state(paused: bool) -> void:
	is_game_paused = paused
	# Emit signal so other systems can react
	game_paused.emit(is_game_paused)
	# Set the tree pause state
	get_tree().paused = is_game_paused

# Toggle the pause state
func toggle_pause() -> void:
	set_pause_state(!is_game_paused)

# Get the current pause state
func is_paused() -> bool:
	return is_game_paused

# Set which projectile type is being used
func set_projectile_type(is_pull: bool) -> void:
	if using_pull_projectile != is_pull:
		using_pull_projectile = is_pull
		projectile_type_changed.emit(using_pull_projectile)

# Get the current projectile type
func is_using_pull_projectile() -> bool:
	return using_pull_projectile

# Toggle the projectile type
func toggle_projectile_type() -> void:
	set_projectile_type(!using_pull_projectile)

# Add any game-wide functionality here
# For example:
# - Global game state
# - Scene transitions with effects
# - Save/load system
# - Global audio management
# - Achievement tracking 

# Load settings from file and apply them
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	if err == OK:
		AudioManager.master_volume = config.get_value("audio", "master_volume", 1.0)
		AudioManager.music_volume = config.get_value("audio", "music_volume", 1.0)
		AudioManager.fx_volume = config.get_value("audio", "fx_volume", 1.0)
		print("Settings loaded from file")
	else:
		print("No settings file found, using defaults")
		AudioManager.master_volume = 1.0
		AudioManager.music_volume = 1.0
		AudioManager.fx_volume = 1.0
	
	# Apply loaded settings
	AudioManager.apply_volume_settings() 

# Save high score for a level if it's better than the current high score
func save_high_score(level_number: int, score: int) -> bool:
	var current_high_score: int = get_high_score(level_number)
	
	# Only save if the new score is higher than the existing one
	if score > current_high_score:
		high_scores[str(level_number)] = score
		save_high_scores()
		return true
	
	return false

# Get the high score for a specific level
func get_high_score(level_number: int) -> int:
	var level_key: String = str(level_number)
	return high_scores.get(level_key, 0)

# Load high scores from file
func load_high_scores() -> void:
	var config = ConfigFile.new()
	var err = config.load(HIGHSCORES_FILE)
	
	if err == OK:
		for level_key in config.get_section_keys("highscores"):
			high_scores[level_key] = config.get_value("highscores", level_key, 0)
		print("High scores loaded from file")
	else:
		print("No high scores file found, using empty dictionary")
		high_scores = {}

# Save high scores to file
func save_high_scores() -> void:
	var config = ConfigFile.new()
	
	for level_key in high_scores.keys():
		config.set_value("highscores", level_key, high_scores[level_key])
	
	var err = config.save(HIGHSCORES_FILE)
	if err == OK:
		print("High scores saved to file")
	else:
		print("Failed to save high scores to file")

# Calculate number of stars based on score
# 100-139: 1 star
# 140-179: 2 stars
# 180-219: 3 stars
# 220-259: 4 stars
# 260-300: 5 stars
func calculate_stars(score: int) -> int:
	if score < 100:
		return 0
	elif score < 140:
		return 1
	elif score < 180:
		return 2
	elif score < 220:
		return 3
	elif score < 260:
		return 4
	else:
		return 5 
