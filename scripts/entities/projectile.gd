extends Area2D

var velocity: Vector2 = Vector2.ZERO
const BASE_SPEED: float = 600.0

func _ready():
	pass

func _process(delta):
	position += velocity * delta

func launch(direction: Vector2, speed_multiplier: float = 1.0) -> void:
	velocity = -direction * (BASE_SPEED * speed_multiplier) 
