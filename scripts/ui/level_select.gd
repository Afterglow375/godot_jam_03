extends Control

const LEVEL_COUNT: int = 11
var levels: Array[String] = []

func _ready():
	# Generate level paths based on count
	for i in range(1, LEVEL_COUNT + 1):
		levels.append("res://scenes/levels/level_%d.tscn" % i)
	
	var buttons = $GridContainer.get_children()
	
	for i in range(min(buttons.size(), levels.size())):
		buttons[i].connect("pressed", Callable(self, "_on_level_selected").bind(i))

# Function to load the selected level
func _on_level_selected(level_index: int) -> void:
	SceneManager.change_scene(levels[level_index])

func _on_back_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/main_menu.tscn")
