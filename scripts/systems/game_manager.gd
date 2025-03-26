extends Node

# This is a minimal GameManager that can be expanded for game-wide functionality
# such as saving/loading, global settings, etc.

# Global game state variables
var is_game_paused: bool = false

# Game state signals
signal game_paused(is_paused)

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

# Add any game-wide functionality here
# For example:
# - Global game state
# - Scene transitions with effects
# - Save/load system
# - Global audio management
# - Achievement tracking 
