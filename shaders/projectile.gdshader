shader_type canvas_item;

// Charge amount from 0.0 to 1.0
uniform float charge_amount : hint_range(0.0, 1.0) = 0.0;
// White fade amount from 0.0 to 1.0
uniform float white_fade_amount : hint_range(0.0, 1.0) = 0.0;
// Charge color - default to red
uniform vec4 charge_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
// Overall opacity from 0.0 to 1.0
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
// Edge distortion effect parameters
uniform float edge_distortion : hint_range(0.0, 0.1) = 0.03;
uniform float distortion_speed : hint_range(0.0, 10.0) = 2.0;
// Edge opacity boost (0.0 = transparent edges, 1.0 = normal, 3.0 = triple opacity at edges)
uniform float edge_opacity : hint_range(0.0, 3.0) = 1.2;
// Enable/disable alpha unpremultiplication (fixes darker colors from viewport textures)
uniform bool unpremultiply_alpha = true;
// Threshold for detecting and removing black silhouette artifacts
uniform float black_threshold : hint_range(0.0, 0.2) = 0.05;

void vertex() {
	// Called for every vertex the material is visible on.
}

// Function to unpremultiply alpha
vec4 unpremultiply(vec4 color) {
    if (color.a <= 0.0) return color;
    return vec4(color.rgb / color.a, color.a);
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
	
	// Fix black silhouette issue in viewport textures
	// Check if the color is very dark (black silhouette) with some alpha
	float luminance = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
	
	// Special handling for the black silhouette issue:
	// If the pixel is very dark but has alpha, it's likely a silhouette artifact
	if (luminance < black_threshold && original_color.a > 0.0 && original_color.a < 0.9) {
		// Make silhouette artifacts fully transparent
		original_color.a = 0.0;
	}
	
	// Unpremultiply alpha if needed (fixes darker colors from viewport textures)
	if (unpremultiply_alpha) {
		original_color = unpremultiply(original_color);
	}
	
	// Only apply effects to non-transparent parts of the texture
	if (original_color.a > 0.0) {
		// Mix original color with charge color based on charge amount
		vec3 charging_color = mix(original_color.rgb, charge_color.rgb, charge_amount);
		
		// Calculate the opacity boost/reduction based on edge proximity
		// When edge_opacity < 1.0, edges will be more transparent
		// When edge_opacity = 1.0, no change
		// When edge_opacity > 1.0, edges will be more opaque
		float opacity_multiplier = edge_opacity * edge_factor + (1.0 - edge_factor);
		
		// Thresholds for effects
		float white_threshold = 0.95;
		
		// CHARGE AMOUNT TAKES PRECEDENCE - handle charge_amount first
		if (charge_amount >= white_threshold) {
			// Calculate how far we are into the fade effect (0.0 to 1.0)
			float fade_progress = (charge_amount - white_threshold) / (1.0 - white_threshold);
			
			// Gradually fade out the alpha, with edge adjustment
			float alpha_fade = original_color.a * (1.0 - fade_progress) * opacity * opacity_multiplier;
			alpha_fade = min(alpha_fade, 1.0); // Clamp to avoid over-bright edges
			
			// Use pure white color (1,1,1) with fading alpha
			COLOR = vec4(1.0, 1.0, 1.0, alpha_fade);
		}
		// Then apply white_fade_amount only if not in charge white threshold mode
		else if (white_fade_amount > 0.0) {
			// Mix between the charging color and white based on white_fade_amount
			vec3 final_color = mix(charging_color, vec3(1.0, 1.0, 1.0), white_fade_amount);
			
			// Maintain alpha (no fading)
			float adjusted_alpha = original_color.a * opacity * opacity_multiplier;
			adjusted_alpha = min(adjusted_alpha, 1.0); // Clamp to avoid over-bright edges
			
			COLOR = vec4(final_color, adjusted_alpha);
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
