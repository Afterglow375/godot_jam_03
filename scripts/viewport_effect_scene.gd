extends Node2D

# This script shows how to integrate the viewport effect in a scene
# Attach this to the root node of your scene

func _ready() -> void:
	# Set up the scene structure for the viewport effect
	setup_scene()
	
func setup_scene() -> void:
	# 1. Create the effect controller node
	var effect_controller = Node2D.new()
	effect_controller.name = "ViewportEffectController"
	effect_controller.script = load("res://scripts/viewport_effect_setup.gd")
	
	# 2. Create a parent node for all the content we want affected
	var content_parent = Node2D.new()
	content_parent.name = "GameContent"
	
	# 3. Move all children to the content parent
	# (except UI elements which should remain outside the effect)
	var children_to_move = []
	for child in get_children():
		if not (child is CanvasLayer) and not (child.name == "ViewportEffectController"):
			children_to_move.append(child)
			
	for child in children_to_move:
		remove_child(child)
		content_parent.add_child(child)
	
	# 4. Add the content parent to the scene first
	add_child(content_parent)
	
	# 5. Then add the effect controller
	add_child(effect_controller)
	
	# 6. Trigger the effect after a delay (for demonstration)
	await get_tree().create_timer(2.0).timeout
	effect_controller.start_effect()

# Example key press to trigger the effect manually
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			var effect_controller = get_node_or_null("ViewportEffectController")
			if effect_controller:
				effect_controller.start_effect()
				
# Example function to trigger the effect from code
func trigger_charge_effect() -> void:
	var effect_controller = get_node_or_null("ViewportEffectController")
	if effect_controller:
		effect_controller.start_effect() 
