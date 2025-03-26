shader_type canvas_item;

// Edge distortion effect parameters
uniform float edge_distortion : hint_range(0.0, 0.1) = 0.03;
uniform float distortion_speed : hint_range(0.0, 10.0) = 2.0;
// Edge opacity boost (0.0 = transparent edges, 1.0 = normal, 3.0 = triple opacity at edges)
uniform float edge_opacity : hint_range(0.0, 3.0) = 1.2;

void fragment() {
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
	
	// Scale the distortion based on edge factor
	wobble *= edge_factor;
	
	// Apply the distortion along the radial direction
	vec2 distorted_uv = UV + direction * wobble;
	
	// Get the original texture color with distorted UVs
	vec4 original_color = texture(TEXTURE, distorted_uv);
	
	// Only apply effects to non-transparent parts of the texture
	if (original_color.a > 0.0) {
		// Calculate the opacity boost/reduction based on edge proximity
		// When edge_opacity < 1.0, edges will be more transparent
		// When edge_opacity = 1.0, no change
		// When edge_opacity > 1.0, edges will be more opaque
		float opacity_multiplier = edge_opacity * edge_factor + (1.0 - edge_factor);
		
		// Apply the edge opacity adjustment to the alpha channel
		float adjusted_alpha = original_color.a * opacity_multiplier;
		adjusted_alpha = min(adjusted_alpha, 1.0); // Clamp to avoid over-bright edges
		
		// Output the color with adjusted alpha
		COLOR = vec4(original_color.rgb, adjusted_alpha);
	} else {
		// Keep fully transparent pixels as is
		COLOR = original_color;
	}
} 