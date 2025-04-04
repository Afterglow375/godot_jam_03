shader_type canvas_item;

// Parameters that can be adjusted in the inspector
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D noise_texture;
uniform float edge_thickness : hint_range(0.01, 0.5) = 0.1;
uniform vec4 edge_color : source_color = vec4(0.6, 0.0, 0.8, 1.0); // Pure purple color
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float brightness : hint_range(0.0, 1.0) = 0.7; // Control overall brightness
uniform vec4 tint_color : source_color = vec4(0.9, 0.87, 0.95, 1.0); // Slight purple tint

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Get the color from the sprite texture
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Apply brightness reduction and tinting to the original color
	// This will tone down bright whites while preserving the original alpha
	tex_color.rgb = tex_color.rgb * brightness * tint_color.rgb;
	
	// Get the noise value from the noise texture, animated over time
	vec2 moving_uv = UV + vec2(sin(TIME * speed * 0.3), cos(TIME * speed * 0.5)) * 0.1;
	float noise_value = texture(noise_texture, moving_uv).r;
	
	// Calculate dissolve edge
	float edge_lower = dissolve_amount - edge_thickness;
	float edge_upper = dissolve_amount;
	
	// Add a subtle pulse effect to the purple color
	vec4 gradient_color = edge_color;
	gradient_color.rgb *= 0.8 + 0.2 * sin(TIME * speed); // Subtle pulsing intensity
	
	// Apply the dissolve effect
	if (noise_value < edge_lower) {
		// Fully dissolved - transparent
		discard;
	} else if (noise_value < edge_upper) {
		// Edge effect - colored gradient
		float t = (noise_value - edge_lower) / (edge_upper - edge_lower);
		tex_color.rgb = mix(gradient_color.rgb, tex_color.rgb, t);
		tex_color.a = tex_color.a * t * 1.5; // Enhance edge alpha a bit
	}
	
	// Apply some additional glow to the edge
	if (noise_value < edge_upper + 0.05) {
		tex_color.rgb += gradient_color.rgb * 0.3 * (1.0 - abs((noise_value - edge_upper) / 0.05));
	}
	
	COLOR = tex_color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
