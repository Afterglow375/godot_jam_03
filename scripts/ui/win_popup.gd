extends CanvasLayer

signal next_level
signal retry_level
signal victory_achieved

var tween: Tween = null
var tween_duration: float = 0.6

func _ready():
	hide()
	
func show_victory_screen(shot_count: int, accuracy_score: int, bonus_score: int, total_score: int, par_penalty: int) -> void:
	emit_signal("victory_achieved")
	show()
	animate_scores(shot_count, accuracy_score, bonus_score, total_score, par_penalty)
	
func animate_scores(shot_count: int, accuracy_score: int, bonus_score: int, total_score: int, par_penalty: int) -> void:
	# Kill any existing tween
	if tween != null:
		tween.kill()
	
	tween = create_tween()
	
	# Animate shots count
	var shots_label = $Panel/VBoxContainer/ShotsLabel
	shots_label.text = "Shots Taken: 0"
	tween.tween_method(
		func(value): shots_label.text = "Shots Taken: " + str(round(value)),
		0.0, shot_count, tween_duration
	)
	
	var penalty_label = $Panel/VBoxContainer/ParPenaltyLabel
	penalty_label.text = "Par Penalty: 0"
	tween.tween_method(
		func(value):
			var color = "[color=crimson]" if par_penalty > 0 else "[color=white]"
			penalty_label.text = "Par Penalty: " + color + str(round(value)) + "[/color]", 0.0, par_penalty, tween_duration
	)
	
	# Animate accuracy score
	var accuracy_label = $Panel/VBoxContainer/AccuracyLabel
	accuracy_label.text = "Accuracy Score: 0"
	tween.parallel().tween_method(
		func(value): accuracy_label.text = "Accuracy Score: " + str(round(value)),
		0.0, accuracy_score, tween_duration
	)
	
	# Animate bonus score
	var bonus_label = $Panel/VBoxContainer/BonusPointsLabel
	bonus_label.text = "Bonus Score: 0"
	tween.parallel().tween_method(
		func(value): bonus_label.text = "Bonus Score: " + str(round(value)),
		0.0, bonus_score, tween_duration
	)
	
	# Animate total score after all other scores are done
	var total_label = $Panel/VBoxContainer/TotalScoreLabel
	total_label.text = "Total Score: 0"
	tween.tween_method(
		func(value): total_label.text = "Total Score: " + str(round(value)),
		0.0, total_score, tween_duration
	)

func _on_level_select_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/level_select.tscn")
	
func _on_retry_button_pressed() -> void:
	emit_signal("retry_level")
	hide()

func _on_next_level_button_pressed() -> void:
	emit_signal("next_level")
	hide()
