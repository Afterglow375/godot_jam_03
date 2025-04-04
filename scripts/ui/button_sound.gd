extends Button

# Automatic sound handling for buttons
# Attach this script to a Button for automatic hover and click sounds

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)
	
	focus_mode = FocusMode.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)

func _on_mouse_entered() -> void:
	AudioManager.play(AudioManager.Audio.BUTTON_HOVER)

func _on_focus_entered() -> void:
	AudioManager.play(AudioManager.Audio.BUTTON_HOVER)

func _on_pressed() -> void:
	AudioManager.play(AudioManager.Audio.BUTTON_CLICK)
