extends Node

## Simple scene manager to handle scene transitions

## Emitted when a scene change operation begins
signal scene_change_started(new_scene_path)

## Emitted when a scene change operation has completed
signal scene_change_completed(new_scene_path)

## Changes to a new scene using the provided path
## @param new_scene_path: String - Path to the scene file to load
## @return Error code from the scene change operation
func change_scene(new_scene_path: String) -> Error:
	scene_change_started.emit(new_scene_path)
	var err = get_tree().change_scene_to_file(new_scene_path)
	if err == OK:
		# Defer the completion signal to ensure it fires after the scene is loaded
		call_deferred("_emit_scene_change_completed", new_scene_path)
	return err

## Emits the scene change completed signal after scene is loaded
## @param scene_path: String - Path of the scene that was loaded
func _emit_scene_change_completed(scene_path: String) -> void:
	scene_change_completed.emit(scene_path)

## Reloads the current scene
## @return Error code from the scene reload operation
func reload_scene() -> Error:
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.scene_file_path:
		return change_scene(current_scene.scene_file_path)
	else:
		push_error("Could not reload scene: current scene path is null")
		return ERR_CANT_CREATE 
