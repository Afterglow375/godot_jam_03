extends Control

func _ready() -> void:
	$VBoxContainer/StartButton.grab_focus()


func _on_start_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/levels/level_1.tscn")


func _on_level_select_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/level_select.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
