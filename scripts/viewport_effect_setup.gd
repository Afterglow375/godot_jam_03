extends Node2D

# This script demonstrates how to set up a viewport-based effect system
# where you can apply effects to specific areas without affecting others

# Reference to the SubViewport
var viewport: SubViewport

# Reference to the viewport texture display
var viewport_display: TextureRect

# Reference to the shader material
var effect_material: ShaderMaterial

func _ready() -> void:
	# Create the viewport system
	setup_viewport_system()
	
func setup_viewport_system() -> void:
	# 1. Create a SubViewport to contain our original scene
	viewport = SubViewport.new()
	viewport.size = get_viewport_rect().size
	viewport.transparent_bg = true
	viewport.handle_input_locally = false  # Pass input to main viewport
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	
	# 2. Move all existing children of this node to the viewport
	# (except for any UI elements that should stay in the main viewport)
	var children_to_move = []
	for child in get_children():
		if child != viewport and not child is CanvasItem:
			children_to_move.append(child)
	
	for child in children_to_move:
		remove_child(child)
		viewport.add_child(child)
	
	# 3. Create a TextureRect to display the viewport texture
	viewport_display = TextureRect.new()
	viewport_display.expand = true
	viewport_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	viewport_display.size = get_viewport_rect().size
	viewport_display.texture = viewport.get_texture()
	add_child(viewport_display)
	
	# 4. Create and apply the shader material
	effect_material = ShaderMaterial.new()
	effect_material.shader = load("res://shaders/viewport_effect.gdshader")
	
	# Set the viewport texture uniform
	effect_material.set_shader_parameter("viewport_texture", viewport.get_texture())
	effect_material.set_shader_parameter("charge_amount", 0.0)  # Start with no effect
	
	viewport_display.material = effect_material
	
	# 5. Handle window resize
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	# Update viewport and display sizes when the window is resized
	viewport.size = get_viewport_rect().size
	viewport_display.size = get_viewport_rect().size

# Public function to set the charge amount (0.0 to 1.0)
func set_charge_amount(amount: float) -> void:
	effect_material.set_shader_parameter("charge_amount", amount)

# Example: Create a tween to animate the charge amount
func animate_charge() -> void:
	var tween = create_tween()
	tween.tween_method(set_charge_amount, 0.0, 1.0, 2.0)
	
# Call this function to start the effect animation
func start_effect() -> void:
	animate_charge() 
