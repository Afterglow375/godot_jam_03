extends CanvasLayer

@onready var master_slider: HSlider = $Settings/Panel/VBoxContainer/MasterVolume/MasterSlider
@onready var music_slider: HSlider = $Settings/Panel/VBoxContainer/MusicVolume/MusicSlider
@onready var fx_slider: HSlider = $Settings/Panel/VBoxContainer/FXVolume/FXSlider
@onready var accept_button: Button = $Settings/Panel/VBoxContainer/HBoxContainer/AcceptButton
@onready var back_button: Button = $Settings/Panel/VBoxContainer/HBoxContainer/BackButton

# Settings file path
const SETTINGS_FILE: String = "user://settings.cfg"

# Store original values when the settings are opened
var original_master_volume: float
var original_music_volume: float 
var original_fx_volume: float

func _ready() -> void:
	# Initialize sliders with current values
	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	fx_slider.value = AudioManager.fx_volume
	
	# Connect signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	fx_slider.value_changed.connect(_on_fx_volume_changed)
	accept_button.pressed.connect(_on_accept_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	hide()

# Load settings from file and apply them
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	if err == OK:
		AudioManager.master_volume = config.get_value("audio", "master_volume", 1.0)
		AudioManager.music_volume = config.get_value("audio", "music_volume", 1.0)
		AudioManager.fx_volume = config.get_value("audio", "fx_volume", 1.0)
		print("Settings loaded from file")
	else:
		print("No settings file found, using defaults")
		AudioManager.master_volume = 1.0
		AudioManager.music_volume = 1.0
		AudioManager.fx_volume = 1.0
	
	# Apply loaded settings
	AudioManager.apply_volume_settings()

# Save settings to file
func save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", AudioManager.master_volume)
	config.set_value("audio", "music_volume", AudioManager.music_volume)
	config.set_value("audio", "fx_volume", AudioManager.fx_volume)
	
	config.save(SETTINGS_FILE)
	print("Settings saved to file")

# Called when the settings popup is shown
func open_settings() -> void:
	# Store original values
	original_master_volume = AudioManager.master_volume
	original_music_volume = AudioManager.music_volume
	original_fx_volume = AudioManager.fx_volume
	
	# Update sliders to current values
	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	fx_slider.value = AudioManager.fx_volume
	
	# Show the settings UI
	show()
	master_slider.grab_focus()

func _on_master_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(value)

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_fx_volume_changed(value: float) -> void:
	AudioManager.set_fx_volume(value)

func _on_accept_button_pressed() -> void:
	# Save the current settings
	save_settings()
	hide()

func _on_back_button_pressed() -> void:
	# Revert to original values
	AudioManager.set_master_volume(original_master_volume)
	AudioManager.set_music_volume(original_music_volume)
	AudioManager.set_fx_volume(original_fx_volume)
	hide()
