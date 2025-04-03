extends Node

# This is a minimal GameManager that can be expanded for game-wide functionality
# such as saving/loading, global settings, etc.

# Global game state variables
var is_game_paused: bool = false
var using_pull_projectile: bool = false  # Track which projectile type is currently selected

# Game state signals
signal game_paused(is_paused)
signal projectile_type_changed(using_pull: bool)  # Signal for projectile type changes

# Settings file path
const SETTINGS_FILE: String = "user://settings.cfg"

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
