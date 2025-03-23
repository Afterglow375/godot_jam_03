shader_type canvas_item;

// Charge amount from 0.0 to 1.0
uniform float charge_amount : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	// Get the original texture color
	vec4 original_color = texture(TEXTURE, UV);
	
	// Only apply effects to non-transparent parts of the texture
	if (original_color.a > 0.0) {
		// Mix original color with red based on charge amount
		vec3 charging_color = mix(original_color.rgb, vec3(1.0, 0.1, 0.1), charge_amount);
		
		// Simple fade out when fully charged
		float fade_threshold = 0.95;
		
		if (charge_amount >= fade_threshold) {
			// Calculate how far we are into the fade effect (0.0 to 1.0)
			float fade_progress = (charge_amount - fade_threshold) / (1.0 - fade_threshold);
			
			// Gradually fade out the alpha
			float alpha_fade = original_color.a * (1.0 - fade_progress);
			
			// When at fade threshold, turn to pure white and then fade out
			vec3 white_color = vec3(1.0, 1.0, 1.0);
			
			// Output with white color and fading alpha
			COLOR = vec4(white_color, alpha_fade);
		} else {
			// Normal charging effect
			COLOR = vec4(charging_color, original_color.a);
		}
	} else {
		// Keep fully transparent pixels as is
		COLOR = original_color;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
