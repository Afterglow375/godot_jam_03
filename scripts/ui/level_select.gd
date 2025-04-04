extends Control

const LEVEL_COUNT: int = 20
var levels: Array[String] = []

func _ready() -> void:
	# Generate level paths based on count
	for i in range(1, LEVEL_COUNT + 1):
		levels.append("res://scenes/levels/level_%d.tscn" % i)
	
	var buttons = $GridContainer.get_children()
	
	for i in range(min(buttons.size(), levels.size())):
		buttons[i].connect("pressed", Callable(self, "_on_level_selected").bind(i))
		var level_label = buttons[i].get_node("HBoxContainer/VBoxContainer/LevelLabel")
		level_label.text = "Level %d" % (i + 1)
		var level_number: int = i + 1
		
		# Check if level is unlocked
		if is_level_unlocked(level_number):
			var high_score: int = GameManager.get_high_score(level_number)
			if high_score > 0:
				var score_label = buttons[i].get_node("HBoxContainer/VBoxContainer2/ScoreLabel")
				score_label.text = str(high_score)
				display_stars(buttons[i], high_score)
		else:
			# Disable and gray out locked levels
			buttons[i].disabled = true
			buttons[i].modulate = Color("#505050")
	
	# Calculate and display the total score
	update_total_score_display()
	
	# Connect to scene change completed signal
	SceneManager.scene_change_completed.connect(_on_scene_change_completed)

# Handle returning to this scene after playing a level
func _on_scene_change_completed(scene_path: String) -> void:
	# Check if we're returning to the level select scene
	if scene_path.ends_with("level_select.tscn"):
		# Recalculate the total score when returning to level select
		call_deferred("update_total_score_display")

# Calculate the sum of all high scores and update the display
func update_total_score_display() -> void:
	var total_score: int = 0
	
	# Sum up all high scores
	for level_number in range(1, LEVEL_COUNT + 1):
		total_score += GameManager.get_high_score(level_number)
	
	# Update the total score label
	var total_score_label: Label = $CanvasLayer/TotalScoreLabel
	total_score_label.text = "Total Score: %d" % total_score

func is_level_unlocked(level_number: int) -> bool:
	# Level 1 is always unlocked
	if level_number == 1:
		return true
		
	# Check if previous level has been completed
	var previous_level_score = GameManager.get_high_score(level_number - 1)
	return previous_level_score > 0

func display_stars(button: Button, score: int) -> void:
	var stars_container = button.get_node("HBoxContainer/VBoxContainer2/MarginContainer/StarsHboxContainer")
	var star_count = GameManager.calculate_stars(score)
	for i in range(1, star_count + 1):
		var control_node = stars_container.get_node("Control" + str(i))
		var gold_star = control_node.get_node("GoldStar")
		gold_star.visible = true

# Function to load the selected level
func _on_level_selected(level_index: int) -> void:
	SceneManager.change_scene(levels[level_index])

func _on_back_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/main_menu.tscn")
