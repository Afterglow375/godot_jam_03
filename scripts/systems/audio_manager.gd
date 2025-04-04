extends Node

# Enum for all available audio clips
enum Audio {
	# Push projectile sounds
	PUSH_PROJECTILE_SHOT,
	PUSH_PROJECTILE_IDLE,
	PUSH_PROJECTILE_CHARGE,
	PUSH_PROJECTILE_DETONATE,
	PUSH_PROJECTILE_FIZZLE,
	PUSH_PROJECTILE_WALL_HIT,
	# Pull projectile sounds
	PULL_PROJECTILE_SHOT,
	PULL_PROJECTILE_IDLE,
	PULL_PROJECTILE_CHARGE,
	PULL_PROJECTILE_DETONATE,
	PULL_PROJECTILE_FIZZLE,
	PULL_PROJECTILE_WALL_HIT,
	# Environment sounds
	EARTH_WALL,
	# Other sounds
	TADAA,
	SUN_HIT,
	EARTH_PUSH,
	# Menu sounds
	THEME_SONG,
	LEVEL_SONG
}

# Dictionary mapping Audio to their file paths and default volumes
var _audio_data = {
	# Push projectile sounds
	Audio.PUSH_PROJECTILE_SHOT: {
		"path": "res://assets/audio/projectile/push_projectile_shot.wav", 
		"volume": -17.0
	},
	Audio.PUSH_PROJECTILE_IDLE: {
		"path": "res://assets/audio/projectile/push_projectile_idle.wav", 
		"volume": -1.0,
		"max_distance": 3000.0
	},
	Audio.PUSH_PROJECTILE_CHARGE: {
		"path": "res://assets/audio/projectile/push_projectile_charge.wav", 
		"volume": -6.0
	},
	Audio.PUSH_PROJECTILE_DETONATE: {
		"path": "res://assets/audio/projectile/push_projectile_detonate.wav", 
		"volume": -5.0
	},
	Audio.PUSH_PROJECTILE_FIZZLE: {
		"path": "res://assets/audio/projectile/push_projectile_fizzle.wav", 
		"volume": -1.0
	},
	Audio.PUSH_PROJECTILE_WALL_HIT: {
		"path": "res://assets/audio/projectile/push_projectile_wall_hit.wav", 
		"volume": -2.0
	},
	# Pull projectile sounds
	Audio.PULL_PROJECTILE_SHOT: {
		"path": "res://assets/audio/projectile/pull_projectile_shot.wav", 
		"volume": -2.0
	},
	Audio.PULL_PROJECTILE_IDLE: {
		"path": "res://assets/audio/projectile/pull_projectile_idle.wav", 
		"volume": 3.0,
		"max_distance": 3000.0
	},
	Audio.PULL_PROJECTILE_CHARGE: {
		"path": "res://assets/audio/projectile/pull_projectile_charge.wav", 
		"volume": -6.0
	},
	Audio.PULL_PROJECTILE_DETONATE: {
		"path": "res://assets/audio/projectile/pull_projectile_detonate.wav", 
		"volume": -5.0
	},
	Audio.PULL_PROJECTILE_FIZZLE: {
		"path": "res://assets/audio/projectile/pull_projectile_fizzle.wav", 
		"volume": -5.0
	},
	Audio.PULL_PROJECTILE_WALL_HIT: {
		"path": "res://assets/audio/projectile/pull_projectile_wall_hit.wav", 
		"volume": -4.0
	},
	# Environment sounds
	Audio.EARTH_WALL: {
		"path": "res://assets/audio/earth_wall.wav", 
		"volume": -3.0
	},
	# Other sounds
	Audio.TADAA: {
		"path": "res://assets/audio/626950__maikkihapsis__tadaa.wav", 
		"volume": -14.0
	},
	Audio.SUN_HIT: {
		"path": "res://assets/audio/sun hit sound.wav", 
		"volume": -15.0
	},
	Audio.EARTH_PUSH: {
		"path": "res://assets/audio/earth push sound.wav", 
		"volume": 0.0,
		"max_distance": 3000.0
	},
	# Menu sounds
	Audio.THEME_SONG: {
		"path": "res://assets/audio/theme_song.wav",
		"volume": -10.0
	},
	Audio.LEVEL_SONG: {
		"path": "res://assets/audio/level_song.wav",
		"volume": -8.0
	}
}

# Audio buses - using names is more reliable than indices
const MASTER_BUS_NAME: String = "Master"
const MUSIC_BUS_NAME: String = "Music"
const FX_BUS_NAME: String = "FX"

# Default volume values (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 1.0
var fx_volume: float = 1.0

# Music player references and settings
var _theme_song_player: AudioStreamPlayer
var _level_song_player: AudioStreamPlayer
var _theme_song_scenes: Array[String] = ["res://scenes/ui/main_menu.tscn", "res://scenes/ui/level_select.tscn", "res://scenes/ui/settings.tscn"]
const MUSIC_FADE_DURATION: float = 0.5

# Preload audio resources for efficiency
var _preloaded_audio = {}

func _ready() -> void:
	# Set process mode to make sure audio manager always runs even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Preload all audio resources
	for clip_id in _audio_data.keys():
		var path = _audio_data[clip_id]["path"]
		_preloaded_audio[clip_id] = load(path)
		
	print("AudioManager initialized with ", _preloaded_audio.size(), " audio clips")
		
	# Connect to SceneManager signals
	SceneManager.scene_change_completed.connect(_on_scene_change_completed)
	
	# Create both music players with silent volume
	_theme_song_player = play(Audio.THEME_SONG, -20, false, false)
	_theme_song_player.volume_db = -20.0  # Start silent
	_theme_song_player.process_mode = Node.PROCESS_MODE_ALWAYS  # Keep playing when paused
	
	_level_song_player = play(Audio.LEVEL_SONG, -20, false, false)
	_level_song_player.volume_db = -20.0  # Start silent
	_level_song_player.process_mode = Node.PROCESS_MODE_ALWAYS  # Keep playing when paused
	
	# Determine which song to play based on current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path
		if _theme_song_scenes.has(scene_path):
			# Start with theme song
			_theme_song_player.play()
			fade_to_song(_theme_song_player, _level_song_player)
		else:
			# Start with level song
			_level_song_player.play()
			fade_to_song(_level_song_player, _theme_song_player)
	else:
		# Default to theme song if we can't determine the scene
		_theme_song_player.play()
		fade_to_song(_theme_song_player, _level_song_player)

func _on_scene_change_completed(scene_path: String) -> void:
	if _theme_song_scenes.has(scene_path):
		# We're in a menu scene - fade in theme song, fade out level song
		fade_to_song(_theme_song_player, _level_song_player)
	else:
		# We're in a gameplay scene - fade in level song, fade out theme song
		fade_to_song(_level_song_player, _theme_song_player)

# Smoothly transition from one song to another
func fade_to_song(fade_in_player: AudioStreamPlayer, fade_out_player: AudioStreamPlayer) -> void:
	if not is_instance_valid(fade_in_player) or not is_instance_valid(fade_out_player):
		return
		
	# Make sure the fade in player is playing
	if not fade_in_player.playing:
		fade_in_player.play()
		
	# Get target volume for the song we're fading in
	var target_db = _get_music_volume_db(fade_in_player)
	
	# Create tweens for fading
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fade_in_player, "volume_db", target_db, MUSIC_FADE_DURATION)
	
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(fade_out_player, "volume_db", -80.0, MUSIC_FADE_DURATION)
	fade_out_tween.tween_callback(func(): 
		if is_instance_valid(fade_out_player):
			fade_out_player.stop()
	)

# Get the appropriate volume in dB for a music player
func _get_music_volume_db(player: AudioStreamPlayer) -> float:
	var clip_id = Audio.THEME_SONG if player == _theme_song_player else Audio.LEVEL_SONG
	var base_volume = _audio_data[clip_id]["volume"]
	return base_volume

# Apply volume settings to audio buses
func apply_volume_settings() -> void:
	# Convert from 0-1 range to decibels (-80 to 0)
	var master_db = linear_to_db(master_volume)
	var music_db = linear_to_db(music_volume)
	var fx_db = linear_to_db(fx_volume)
	
	# Get indices for the buses
	var master_idx = AudioServer.get_bus_index(MASTER_BUS_NAME)
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	var fx_idx = AudioServer.get_bus_index(FX_BUS_NAME)
	
	# Apply to audio buses
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, master_db)
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, music_db)
	if fx_idx >= 0:
		AudioServer.set_bus_volume_db(fx_idx, fx_db)

# Set master volume (0.0 to 1.0)
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	var master_idx = AudioServer.get_bus_index(MASTER_BUS_NAME)
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))

# Set music volume (0.0 to 1.0)
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
		
	# If music is currently playing, update its volume directly
	if _theme_song_player and is_instance_valid(_theme_song_player) and _theme_song_player.playing:
		var theme_target_db = _get_music_volume_db(_theme_song_player)
		_theme_song_player.volume_db = theme_target_db
		
	if _level_song_player and is_instance_valid(_level_song_player) and _level_song_player.playing:
		var level_target_db = _get_music_volume_db(_level_song_player)
		_level_song_player.volume_db = level_target_db

# Set fx volume (0.0 to 1.0)
func set_fx_volume(volume: float) -> void:
	fx_volume = clamp(volume, 0.0, 1.0)
	var fx_idx = AudioServer.get_bus_index(FX_BUS_NAME)
	if fx_idx >= 0:
		AudioServer.set_bus_volume_db(fx_idx, linear_to_db(fx_volume))

# Play an audio clip at the specified volume (can override default volume)
# Returns the created AudioStreamPlayer so you can connect to its signals if needed
func play(clip_id: int, override_volume: float = -100, autoplay: bool = true, autocleanup: bool = true) -> AudioStreamPlayer:
	if not _audio_data.has(clip_id):
		push_error("AudioManager: Invalid audio clip ID: " + str(clip_id))
		return null
		
	if not _preloaded_audio.has(clip_id) or _preloaded_audio[clip_id] == null:
		push_error("AudioManager: Audio clip not preloaded: " + str(clip_id))
		return null
	
	# Create a new AudioStreamPlayer
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	# Set the stream and volume
	player.stream = _preloaded_audio[clip_id]
	var volume = override_volume if override_volume != -100 else _audio_data[clip_id]["volume"]
	player.volume_db = volume
	
	# Set appropriate bus
	if clip_id == Audio.THEME_SONG or clip_id == Audio.LEVEL_SONG:
		player.bus = MUSIC_BUS_NAME
		# Make music continue playing during pause
		player.process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		player.bus = FX_BUS_NAME
	
	# Connect the finished signal to auto-cleanup if enabled
	if autocleanup:
		player.finished.connect(player.queue_free)
	
	# Play the sound if autoplay is enabled
	if autoplay:
		player.play()
	
	return player

# Play an audio clip at a specific 2D position
# Returns the created AudioStreamPlayer2D so you can connect to its signals if needed
func play_positional(clip_id: int, position: Vector2, override_volume: float = -100, autoplay: bool = true, autocleanup: bool = true) -> AudioStreamPlayer2D:
	if not _audio_data.has(clip_id):
		push_error("AudioManager: Invalid audio clip ID: " + str(clip_id))
		return null
		
	if not _preloaded_audio.has(clip_id) or _preloaded_audio[clip_id] == null:
		push_error("AudioManager: Audio clip not preloaded: " + str(clip_id))
		return null
	
	# Create a new AudioStreamPlayer2D
	var player = AudioStreamPlayer2D.new()
	add_child(player)
	
	# Set the stream and volume
	player.stream = _preloaded_audio[clip_id]
	var volume = override_volume if override_volume != -100 else _audio_data[clip_id]["volume"]
	player.volume_db = volume
	
	# Set the position
	player.position = position
	
	# Set appropriate bus (all positional sounds are FX)
	player.bus = FX_BUS_NAME
	
	# Set max_distance if specified in _audio_data
	if _audio_data[clip_id].has("max_distance"):
		player.max_distance = _audio_data[clip_id]["max_distance"]
	
	# Connect the finished signal to auto-cleanup if enabled
	if autocleanup:
		player.finished.connect(player.queue_free)
	
	# Play the sound if autoplay is enabled
	if autoplay:
		player.play()
	
	return player

# Called when the node is about to be removed from the SceneTree
func _exit_tree() -> void:
	# Clean up the music players if they exist
	if _theme_song_player and is_instance_valid(_theme_song_player):
		_theme_song_player.stop()
		_theme_song_player.queue_free()
		
	if _level_song_player and is_instance_valid(_level_song_player):
		_level_song_player.stop()
		_level_song_player.queue_free()
