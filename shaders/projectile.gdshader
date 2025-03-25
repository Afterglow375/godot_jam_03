shader_type canvas_item;

// Charge amount from 0.0 to 1.0
uniform float charge_amount : hint_range(0.0, 1.0) = 0.0;
// Overall opacity from 0.0 to 1.0
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
// Edge distortion effect parameters
uniform float edge_distortion : hint_range(0.0, 0.1) = 0.03;
uniform float distortion_speed : hint_range(0.0, 10.0) = 2.0;
// Edge opacity boost (0.0 = transparent edges, 1.0 = normal, 3.0 = triple opacity at edges)
uniform float edge_opacity : hint_range(0.0, 3.0) = 1.2;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	// Calculate distance from center of sprite (assuming UV origin is at center)
	vec2 centered_uv = UV - 0.5;
	float dist_from_center = length(centered_uv);
	
	// Calculate normalized direction from center
	vec2 direction = normalize(centered_uv);
	
	// Only distort near the edges (dist > 0.4) and increase effect as we get closer to edge
	float edge_factor = smoothstep(0.3, 0.5, dist_from_center);
	
	// Create a time-based distortion that varies around the edge
	float angle = atan(direction.y, direction.x);
	float wobble = sin(angle * 6.0 + TIME * distortion_speed) * edge_distortion;
	
	// Scale the distortion based on charge and edge factor
	wobble *= edge_factor * (1.0 + charge_amount);
	
	// Apply the distortion along the radial direction
	vec2 distorted_uv = UV + direction * wobble;
	
	// Get the original texture color with distorted UVs
	vec4 original_color = texture(TEXTURE, distorted_uv);
	
	// Only apply effects to non-transparent parts of the texture
	if (original_color.a > 0.0) {
		// Mix original color with red based on charge amount
		vec3 charging_color = mix(original_color.rgb, vec3(1.0, 0.1, 0.1), charge_amount);
		
		// Calculate the opacity boost/reduction based on edge proximity
		// When edge_opacity < 1.0, edges will be more transparent
		// When edge_opacity = 1.0, no change
		// When edge_opacity > 1.0, edges will be more opaque
		float opacity_multiplier = edge_opacity * edge_factor + (1.0 - edge_factor);
		
		// Simple fade out when fully charged
		float fade_threshold = 0.95;
		
		if (charge_amount >= fade_threshold) {
			// Calculate how far we are into the fade effect (0.0 to 1.0)
			float fade_progress = (charge_amount - fade_threshold) / (1.0 - fade_threshold);
			
			// Gradually fade out the alpha, with edge adjustment
			float alpha_fade = original_color.a * (1.0 - fade_progress) * opacity * opacity_multiplier;
			alpha_fade = min(alpha_fade, 1.0); // Clamp to avoid over-bright edges
			
			// When at fade threshold, turn to pure white and then fade out
			vec3 white_color = vec3(1.0, 1.0, 1.0);
			
			// Output with white color and fading alpha
			COLOR = vec4(white_color, alpha_fade);
		} else {
			// Normal charging effect with opacity applied and edge adjustment
			float adjusted_alpha = original_color.a * opacity * opacity_multiplier;
			adjusted_alpha = min(adjusted_alpha, 1.0); // Clamp to avoid over-bright edges
			
			COLOR = vec4(charging_color, adjusted_alpha);
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
