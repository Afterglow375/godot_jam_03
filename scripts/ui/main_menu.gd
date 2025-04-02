extends Control

func _ready() -> void:
	# Play the fade-in animation (dissolve in reverse) when main menu starts
	if SceneManager and SceneManager.animation_player:
		# Set the ColorRect to fully opaque first
		var color_rect = SceneManager.get_node("ColorRect")
		if color_rect:
			color_rect.modulate.a = 1.0
		# Play the dissolve animation in reverse at normal speed
		var anim_length = SceneManager.animation_player.get_animation("dissolve").length
		SceneManager.animation_player.play("dissolve", 0.0, -1.0, anim_length)
	
	$VBoxContainer/StartButton.grab_focus()


func _on_start_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/levels/level_1.tscn")


func _on_level_select_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/level_select.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
