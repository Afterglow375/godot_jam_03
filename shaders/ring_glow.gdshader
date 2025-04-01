shader_type canvas_item;
render_mode blend_add;

uniform vec4 ring_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float visibility : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // Sample the original texture
    vec4 original = texture(TEXTURE, UV);
    
    // Calculate distance from center (normalized coordinates)
    vec2 center_uv = UV * 2.0 - 1.0;
    float dist = length(center_uv);
    
    // Create the visibility factor - increases from inside out based on visibility parameter
    // When visibility = 0, everything is invisible
    // As visibility increases, the ring fades in from inner to outer
    float fade_factor = smoothstep(0.0, 1.0, visibility * 2.0 - dist);
    fade_factor = clamp(fade_factor, 0.0, 1.0);
    
    // Apply visibility to original sprite
    float final_alpha = original.a * fade_factor;
    
    // Combine original texture with our effects
    vec4 final_color = original;
    final_color.rgb = ring_color.rgb;
    final_color.a = final_alpha;
    
    COLOR = final_color;
} 