extends Node

# This is a minimal GameManager that can be expanded for game-wide functionality
# such as saving/loading, global settings, etc.

# Global game state variables
var is_game_paused: bool = false
var using_pull_projectile: bool = false  # Track which projectile type is currently selected

# Game state signals
signal game_paused(is_paused)
signal projectile_type_changed(using_pull: bool)  # Signal for projectile type changes

func _ready() -> void:
	# Set process mode to always so the manager works even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

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
