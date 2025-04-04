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
		var high_score: int = GameManager.get_high_score(level_number)
		if high_score > 0:
			var score_label = buttons[i].get_node("HBoxContainer/VBoxContainer2/ScoreLabel")
			score_label.text = str(high_score)
			
			display_stars(buttons[i], high_score)

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
