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
	THEME_SONG
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
		"volume": -14.0
	},
	Audio.EARTH_PUSH: {
		"path": "res://assets/audio/earth push sound.wav", 
		"volume": 0.0,
		"max_distance": 3000.0
	},
	# Menu sounds
	Audio.THEME_SONG: {
		"path": "res://assets/audio/theme_song.wav",
		"volume": -12.0
	}
}

# Preload audio resources for efficiency
var _preloaded_audio = {}
var _theme_song_player: AudioStreamPlayer
var _theme_song_scenes: Array[String] = ["res://scenes/ui/main_menu.tscn", "res://scenes/ui/level_select.tscn"]

func _ready() -> void:
	# Preload all audio resources
	for clip_id in _audio_data.keys():
		var path = _audio_data[clip_id]["path"]
		_preloaded_audio[clip_id] = load(path)
		
	print("AudioManager initialized with ", _preloaded_audio.size(), " audio clips")
		
	# Connect to SceneManager signals
	SceneManager.scene_change_completed.connect(_on_scene_change_completed)
	
	_theme_song_player = play(Audio.THEME_SONG, -100, true, false)

func _on_scene_change_completed(scene_path: String) -> void:
	if _theme_song_scenes.has(scene_path):
		if _theme_song_player == null or !is_instance_valid(_theme_song_player):
			_theme_song_player = play(Audio.THEME_SONG, -100, true, false)
	else:
		# Stop the theme song when not in menu scenes
		if _theme_song_player != null and is_instance_valid(_theme_song_player):
			_theme_song_player.stop()
			_theme_song_player.queue_free()
			_theme_song_player = null

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
