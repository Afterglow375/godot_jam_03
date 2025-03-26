extends CanvasLayer

var level: Node = null

func _ready() -> void:
	# Store reference to the level
	level = get_tree().current_scene
	
	# Connect the buttons to their respective functions
	$Control/Panel/VBoxContainer/Continue.pressed.connect(_on_continue_pressed)
	$Control/Panel/VBoxContainer/Retry.pressed.connect(_on_retry_pressed)
	$Control/Panel/VBoxContainer/Exit.pressed.connect(_on_exit_pressed)

func _on_continue_pressed() -> void:
	# Call the level's toggle_pause_menu function to properly unpause the game
	level.toggle_pause_menu()

func _on_retry_pressed() -> void:
	# First unpause the game using the game manager
	level.game_manager.set_pause_state(false)
	
	level.reset_score()
	level.reset_level()

func _on_exit_pressed() -> void:
	# First unpause the game using the game manager
	level.game_manager.set_pause_state(false)
	
	# Go to the main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

			
