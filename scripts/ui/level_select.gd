extends Control

const levels = [
	"res://scenes/levels/level_one.tscn"
]

func _ready():
	var buttons = $GridContainer.get_children()
	
	for i in range(min(buttons.size(), levels.size())):
		buttons[i].connect("pressed", Callable(self, "_on_level_selected").bind(i))

# Function to load the selected level
func _on_level_selected(level_index):
	get_tree().change_scene_to_file(levels[level_index])

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")
