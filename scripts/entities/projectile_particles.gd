extends GPUParticles2D

@onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")

func _ready():
	animation_player.play("RESET")

func play() -> void:
	animation_player.play("charging_explosion")
	
func is_playing() -> bool:
	return animation_player.is_playing()
