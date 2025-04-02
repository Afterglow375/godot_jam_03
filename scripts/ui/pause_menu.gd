extends CanvasLayer

var level: Node = null

func _ready() -> void:
	# Connect the buttons to their respective functions
	$Control/Panel/VBoxContainer/Continue.pressed.connect(_on_continue_pressed)
	$Control/Panel/VBoxContainer/Retry.pressed.connect(_on_retry_pressed)
	$Control/Panel/VBoxContainer/Exit.pressed.connect(_on_exit_pressed)
	
	# Get the level reference - use deferred to ensure scene is ready
	call_deferred("_setup_level_reference")

func _setup_level_reference() -> void:
	level = get_tree().current_scene

func _on_continue_pressed() -> void:
	level.toggle_pause_menu()

func _on_retry_pressed() -> void:
	level.reset_level()

func _on_exit_pressed() -> void:
	# Ensure we're not paused when exiting to menu
	GameManager.set_pause_state(false)
	
	# Go to the main menu
	SceneManager.change_scene("res://scenes/ui/main_menu.tscn")
