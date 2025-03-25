extends Node

# Enum for all available audio clips
enum Audio {
	PROJECTILE_SHOT,
	PROJECTILE_WALL,
	PROJECTILE_SOUND,
	EARTH_WALL,
	DETONATE_EXPLOSION_CHARGE,
	DETONATE_EXPLOSION,
	EXPLOSION_FIZZLE,
	TADAA,
	SUN_HIT,
	EARTH_PUSH
}

# Dictionary mapping Audio to their file paths and default volumes
var _audio_data = {
	Audio.PROJECTILE_SHOT: {
		"path": "res://assets/audio/projectile_shot.wav", 
		"volume": -14.0
	},
	Audio.PROJECTILE_WALL: {
		"path": "res://assets/audio/projectile_wall.wav", 
		"volume": -2.0
	},
	Audio.PROJECTILE_SOUND: {
		"path": "res://assets/audio/projectile sound.wav", 
		"volume": -5.0,
		"max_distance": 3000.0
	},
	Audio.EXPLOSION_FIZZLE: {
		"path": "res://assets/audio/explosion_fizzle.wav", 
		"volume": -1.0
	},
	Audio.EARTH_WALL: {
		"path": "res://assets/audio/earth_wall.wav", 
		"volume": -3.0
	},
	Audio.DETONATE_EXPLOSION_CHARGE: {
		"path": "res://assets/audio/detonate_explosion_charge.wav", 
		"volume": -6.0
	},
	Audio.DETONATE_EXPLOSION: {
		"path": "res://assets/audio/detonate_explosion.wav", 
		"volume": -5.0
	},
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
	}
}

# Preload audio resources for efficiency
var _preloaded_audio = {}

func _ready() -> void:
	# Preload all audio resources
	for clip_id in _audio_data.keys():
		var path = _audio_data[clip_id]["path"]
		_preloaded_audio[clip_id] = load(path)
		
	print("AudioManager initialized with ", _preloaded_audio.size(), " audio clips")

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
