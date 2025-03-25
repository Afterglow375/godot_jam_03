extends Node

# Enum for all available audio clips
enum Audio {
	PROJECTILE_SHOT,
	PROJECTILE_WALL,
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
		"path": "res://assets/audio/earth push sound2.wav", 
		"volume": -5.0
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
func play(clip_id: int, override_volume: float = -100, play: bool = true, delete: bool = true) -> AudioStreamPlayer:
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
	
	# Connect the finished signal to auto-cleanup
	if delete:
		player.finished.connect(player.queue_free)
	
	# Play the sound
	if play:
		player.play()
	
	return player
