extends Node2D

var label: Label = null
var accuracy_score: int = 0
var bonus_points: int = 0
var shader_material: ShaderMaterial = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get reference to label
	label = $Label
	
	# Hide initially
	visible = false
	
	# Get shader material from label
	shader_material = label.material

func show_with_animation() -> void:
	visible = true
	modulate.a = 0
	scale = Vector2.ZERO
	
	var tween = create_tween()
	if tween == null:
		return
		
	tween.set_parallel(true)
	tween.tween_property(
		self, "position:y", position.y + 24, 0.125
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self, "position:y", position.y, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.125)
	tween.tween_property(
		self, "scale", Vector2.ONE, 0.25
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self, "modulate:a", 1.0, 0.125
	).set_ease(Tween.EASE_OUT)

func hide_with_animation() -> void:
	var tween = create_tween()
	if tween == null:
		return
		
	tween.tween_property(
		self, "modulate:a", 0.0, 0.25
	).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false)

func update_accuracy_score(new_score: int) -> void:
	accuracy_score = new_score
	update_display()

func update_bonus_points(points: int) -> void:
	bonus_points = points
	update_display()
	
	# Update shader fire intensity based on bonus points (0-100)
	if shader_material:
		shader_material.set_shader_parameter("fire_intensity", points / 100.0)

func update_display() -> void:
	label.text = str(accuracy_score + bonus_points)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
