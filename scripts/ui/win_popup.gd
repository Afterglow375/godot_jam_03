extends CanvasLayer

signal next_level
signal retry_level
signal victory_achieved

var tween: Tween = null
var tween_duration: float = 0.2

func _ready() -> void:
	hide()
	# Hide high score label by default
	$Panel/VBoxContainer/HBoxContainer/HighScoreLabel.visible = false

func show_victory_screen(accuracy_score: int, bonus_score: int, par_penalty: int, current_hiscore: int) -> void:
	emit_signal("victory_achieved")
	show()
	
	var total_score = accuracy_score + bonus_score - par_penalty
	
	var high_score_label = $Panel/VBoxContainer/HBoxContainer/HighScoreLabel
	high_score_label.visible = false
	
	var is_new_hiscore = total_score > current_hiscore
	current_hiscore = total_score if is_new_hiscore else current_hiscore
	
	# Display stars based on the score
	display_stars(total_score)
	
	animate_scores(accuracy_score, bonus_score, par_penalty, current_hiscore)
	
	# If new high score, show it after delay
	if is_new_hiscore:
		var timer = get_tree().create_timer(1)
		await timer.timeout
		
		high_score_label.visible = true
		
		# Create bounce animation
		animate_high_score_label(high_score_label)

# Display star ratings based on score
func display_stars(score: int) -> void:
	var stars_container = $Panel/StarsHboxContainer
	var star_count = GameManager.calculate_stars(score)
	
	# Then activate the appropriate number of gold stars with animation
	for i in range(1, star_count + 1):
		var control_node = stars_container.get_node("Control" + str(i))
		var gold_star = control_node.get_node("GoldStar")
		
		# Create a short delay before showing each star
		var timer = get_tree().create_timer(0.1 * i)
		await timer.timeout
		
		# Show the star with a scale animation
		gold_star.scale = Vector2(0.3, 0.3)
		gold_star.visible = true
		
		# Create animation tween
		var tween = create_tween()
		tween.tween_property(gold_star, "scale", Vector2(0.55, 0.55), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func animate_high_score_label(label: RichTextLabel) -> void:
	var original_position = label.position
	
	var bounce_tween = create_tween().set_loops()
	
	# Move up and down with easing
	bounce_tween.tween_property(label, "position:y", original_position.y - 10, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(label, "position:y", original_position.y, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var text_content = """[font_size=64][wave amp=30 freq=5][color=#FFD700]NEW HIGH SCORE!!![/color][/wave][/font_size]"""
	
	label.text = text_content

func animate_scores(accuracy_score: int, bonus_score: int, par_penalty: int, hiscore: int) -> void:
	# Kill any existing tween
	if tween != null:
		tween.kill()
	
	tween = create_tween()
	
	var penalty_label = $Panel/VBoxContainer/ParPenaltyLabel
	penalty_label.text = "Par Penalty: 0"
	tween.tween_method(
		func(value):
			var color = "[color=crimson]" if par_penalty > 0 else "[color=white]"
			var penalty_text = "0" if par_penalty == 0 else "-" + str(round(value))
			penalty_label.text = "Par Penalty: " + color + penalty_text + "[/color]", 0.0, par_penalty, tween_duration
	)
	
	# Animate accuracy score
	var accuracy_label = $Panel/VBoxContainer/AccuracyLabel
	accuracy_label.text = "Accuracy Score: 0"
	tween.tween_method(
		func(value): accuracy_label.text = "Accuracy Score: " + str(round(value)),
		0.0, accuracy_score, tween_duration
	)
	
	# Animate bonus score
	var bonus_label = $Panel/VBoxContainer/BonusPointsLabel
	bonus_label.text = "Bonus Score: 0"
	tween.tween_method(
		func(value): bonus_label.text = "Bonus Score: " + str(round(value)),
		0.0, bonus_score, tween_duration
	)
	
	# Animate total score after all other scores are done
	var total_score = accuracy_score + bonus_score - par_penalty
	var total_label = $Panel/VBoxContainer/HBoxContainer/TotalScoreLabel
	total_label.text = "Total Score: 0"
	tween.tween_method(
		func(value): total_label.text = "Total Score: " + str(round(value)),
		0.0, total_score, tween_duration
	)
	
	# Animate hiscore
	var hiscore_label = $Panel/VBoxContainer/HiscoreLabel
	hiscore_label.text = "Hiscore: 0"
	tween.tween_method(
		func(value): hiscore_label.text = "Hiscore: " + str(round(value)),
		0.0, hiscore, tween_duration
	)
	
func _on_level_select_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/level_select.tscn")
	
func _on_retry_button_pressed() -> void:
	emit_signal("retry_level")
	hide()

func _on_next_level_button_pressed() -> void:
	emit_signal("next_level")
	hide()
