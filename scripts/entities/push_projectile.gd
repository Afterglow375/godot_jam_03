extends "res://scripts/entities/base_projectile.gd"
# Push projectile - extends the base projectile
# Uses push-specific sounds and explosion force is handled by push_outer_projectile

# Override to use push-specific idle sound
func create_projectile_sound_player() -> void:
	projectile_sound_player = audio_manager.play_positional(
		AudioManager.Audio.PUSH_PROJECTILE_IDLE,
		outer_projectile.global_position,
		false,
		false
	)
	
	projectile_sound_player.play()

# Override to use push-specific launch sound
func play_launch_sound() -> void:
	audio_manager.play(AudioManager.Audio.PUSH_PROJECTILE_SHOT)

# Override to use push-specific charge sound
func play_charge_sound() -> void:
	audio_manager.play(AudioManager.Audio.PUSH_PROJECTILE_CHARGE)

# Override to use push-specific detonate sound
func play_detonate_sound() -> void:
	audio_manager.play(AudioManager.Audio.PUSH_PROJECTILE_DETONATE)

# Override to use push-specific fizzle sound
func play_fizzle_sound() -> void:
	audio_manager.play(AudioManager.Audio.PUSH_PROJECTILE_FIZZLE)

# Override to use push-specific wall collision sound
func play_wall_collision_sound() -> void:
	audio_manager.play(AudioManager.Audio.PUSH_PROJECTILE_WALL_HIT)

