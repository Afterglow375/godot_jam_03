extends CanvasLayer

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	GameManager.toggle_pause()

func _on_close_button_pressed() -> void:
	GameManager.toggle_pause()
	hide()
