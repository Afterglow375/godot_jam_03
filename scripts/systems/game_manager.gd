extends Node

var current_level_path: String = ""
var is_current_scene_level: bool = false

func _ready() -> void:
	# Connect to the tree to detect scene changes
	get_tree().root.connect("ready", Callable(self, "_on_scene_ready"))

func _on_scene_ready() -> void:
	# Store the current scene path when a new scene is loaded
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.scene_file_path:
		current_level_path = current_scene.scene_file_path
		# Check if this is a level scene
		is_current_scene_level = _is_level_scene(current_level_path)

func _input(event: InputEvent) -> void:
	# Check for the R key press to reset the level, but only in level scenes
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and is_current_scene_level:
		reset_level()

func reset_level() -> void:
	# Reload the current level
	get_tree().change_scene_to_file(current_level_path)

# Determines if a scene is a level scene based on its path
func _is_level_scene(scene_path: String) -> bool:
	if "scenes/levels/" in scene_path:
		return true
	return false 
