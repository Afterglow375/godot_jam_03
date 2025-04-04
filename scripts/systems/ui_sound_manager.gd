extends Node

# UI Sound Manager - automatically adds sound effects to UI elements
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SceneManager.scene_change_completed.connect(_on_scene_change_completed)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_process_existing_buttons")

func _on_scene_change_completed(_scene_path: String) -> void:
	# Process buttons in the new scene after a short delay to ensure all nodes are ready
	await get_tree().create_timer(0.1).timeout
	_process_existing_buttons()

func _process_existing_buttons() -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
		
	var buttons = _find_all_buttons(current_scene)
	
	for button in buttons:
		if is_instance_valid(button):
			_attach_sounds_to_button(button)

func _find_all_buttons(node: Node) -> Array:
	var buttons = []
	
	if node == null:
		return buttons
	
	if node is Button:
		if not _has_button_sound_script(node):
			buttons.append(node)
	
	for child in node.get_children():
		if is_instance_valid(child):
			buttons.append_array(_find_all_buttons(child))
	
	return buttons

func _on_node_added(node: Node) -> void:
	if not is_instance_valid(node):
		return
		
	if node is Button and not _has_button_sound_script(node):
		_attach_sounds_to_button(node)

func _has_button_sound_script(node: Node) -> bool:
	if not is_instance_valid(node) or node.get_script() == null:
		return false
		
	var script_path = node.get_script().resource_path
	return script_path == "res://scripts/ui/button_sound.gd"

func _attach_sounds_to_button(button: Button) -> void:
	if not is_instance_valid(button):
		return
		
	if button.get_class() != "Button" and button.get_class() != "TextureButton":
		return
		
	if not button.mouse_entered.is_connected(_on_button_mouse_entered):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed.bind(button))
	
	if not button.focus_entered.is_connected(_on_button_focus_entered):
		button.focus_entered.connect(_on_button_focus_entered.bind(button))
		button.focus_mode = Control.FOCUS_ALL

func _on_button_mouse_entered(button: Button) -> void:
	AudioManager.play(AudioManager.Audio.BUTTON_HOVER)

func _on_button_focus_entered(button: Button) -> void:
	AudioManager.play(AudioManager.Audio.BUTTON_HOVER)

func _on_button_pressed(button: Button) -> void:
	AudioManager.play(AudioManager.Audio.BUTTON_CLICK)
