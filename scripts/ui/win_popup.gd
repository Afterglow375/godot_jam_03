extends CanvasLayer

signal next_level
signal retry_level
signal victory_achieved

func _ready():
	hide()
	
func show_victory_screen(shot_count: int, accuracy_score: int, bonus_score: int) -> void:
	emit_signal("victory_achieved")
	set_scores(shot_count, accuracy_score, bonus_score)
	show()
	
func set_scores(shot_count: int, accuracy_score: int, bonus_score: int):
	var total_score = 0 if shot_count == 0 else round(accuracy_score / shot_count) + bonus_score

	$Panel/VBoxContainer/ShotsLabel.text = "Shots Taken: " + str(shot_count)
	$Panel/VBoxContainer/AccuracyLabel.text = "Accuracy Score: " + str(accuracy_score)
	$Panel/VBoxContainer/BonusPointsLabel.text = "Bonus Score: " + str(bonus_score)
	$Panel/VBoxContainer/TotalScoreLabel.text = "Total Score: " + str(total_score)

func _on_level_select_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
	
func _on_retry_button_pressed() -> void:
	emit_signal("retry_level")
	hide()

func _on_next_level_button_pressed() -> void:
	emit_signal("next_level")
	hide()
