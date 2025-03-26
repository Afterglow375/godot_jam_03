extends CanvasLayer

signal next_level
signal retry_level
signal victory_achieved

var tween: Tween = null

func _ready():
	hide()
	
func show_victory_screen(shot_count: int, accuracy_score: int, bonus_score: int) -> void:
	emit_signal("victory_achieved")
	show()
	animate_scores(shot_count, accuracy_score, bonus_score)
	
func animate_scores(shot_count: int, accuracy_score: int, bonus_score: int) -> void:
	# Kill any existing tween
	if tween != null:
		tween.kill()
	
	tween = create_tween()
	
	# Animate shots count
	var shots_label = $Panel/VBoxContainer/ShotsLabel
	shots_label.text = "Shots Taken: 0"
	tween.tween_method(
		func(value): shots_label.text = "Shots Taken: " + str(round(value)),
		0.0, shot_count, 1.0
	)
	
	# Animate accuracy score
	var accuracy_label = $Panel/VBoxContainer/AccuracyLabel
	accuracy_label.text = "Accuracy Score: 0"
	tween.parallel().tween_method(
		func(value): accuracy_label.text = "Accuracy Score: " + str(round(value)),
		0.0, accuracy_score, 1.0
	)
	
	# Animate bonus score
	var bonus_label = $Panel/VBoxContainer/BonusPointsLabel
	bonus_label.text = "Bonus Score: 0"
	tween.parallel().tween_method(
		func(value): bonus_label.text = "Bonus Score: " + str(round(value)),
		0.0, bonus_score, 1.0
	)
	
	# Animate total score after all other scores are done
	var total_score = 0 if shot_count == 0 else round(accuracy_score / shot_count) + bonus_score
	var total_label = $Panel/VBoxContainer/TotalScoreLabel
	total_label.text = "Total Score: 0"
	tween.tween_method(
		func(value): total_label.text = "Total Score: " + str(round(value)),
		0.0, total_score, 1.0
	)

func _on_level_select_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
	
func _on_retry_button_pressed() -> void:
	emit_signal("retry_level")
	hide()

func _on_next_level_button_pressed() -> void:
	emit_signal("next_level")
	hide()
