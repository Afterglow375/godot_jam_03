shader_type canvas_item;
render_mode blend_mix;

// Texture parameters (for tinting)
group_uniforms render;
uniform vec4 tint_color: source_color = vec4(0.0, 0.0, 0.0, 0.0);

// Wave and chromatic aberration parameters
group_uniforms effects;
uniform float wave_amplitude: hint_range(0.0, 0.01) = 0.006;  
uniform float wave_frequency: hint_range(0.0, 20.0) = 19.397;  
uniform float wave_speed: hint_range(0.0, 10.0) = 3.618;  
uniform float chroma_amount: hint_range(0.0, 1.0) = 1.0; 

// Star field parameters 
group_uniforms stars;
uniform bool stars_enabled = true;      
uniform float star_field_scale: hint_range(1.0, 50.0) = 4.377;  
uniform float star_size: hint_range(0.001, 0.05) = 0.008;      
uniform float star_intensity: hint_range(0.0, 1.0) = 1.0;     
uniform float star_axis_speed: hint_range(0.0, 0.5) = 0.051;  
uniform int star_move_mode: hint_range(0, 3) = 1;  

// Helper function for random number generation.
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Apply wave distortion
    vec2 wave_offset = vec2(
        sin(UV.y * wave_frequency + TIME * wave_speed),
        sin(UV.x * wave_frequency + TIME * wave_speed)
    ) * wave_amplitude;
    
    vec2 distorted_uv = UV + wave_offset;
    
    // Chromatic aberration: offset red and blue channels.
    vec2 red_uv   = distorted_uv + wave_offset * chroma_amount;
    vec2 blue_uv  = distorted_uv - wave_offset * chroma_amount;
    vec2 green_uv = distorted_uv;
    
    // In 2D, we need to sample the texture directly
    vec4 original_color = texture(TEXTURE, distorted_uv);
    float r = texture(TEXTURE, red_uv).r;
    float g = texture(TEXTURE, green_uv).g;
    float b = texture(TEXTURE, blue_uv).b;
    vec4 scene_color = vec4(r, g, b, original_color.a); // Preserve alpha
    
    // Mix the scene color with the tint.
    vec3 final_color = mix(scene_color.rgb, tint_color.rgb, tint_color.a);

    // Star Field Generation
    float star_accum = 0.0;
    if (stars_enabled) {
        vec2 moving_uv = UV;

        // Compute an offset based on the movement mode.
        vec2 offset = vec2(0.0);
        if (star_move_mode == 0) {
            offset = vec2(0.0, TIME * star_axis_speed);
        } else if (star_move_mode == 1) {
            offset = vec2(TIME * star_axis_speed, 0.0);
        } else if (star_move_mode == 2) {
            offset = vec2(TIME * star_axis_speed, TIME * star_axis_speed);
        } else if (star_move_mode == 3) {
            offset = vec2(sin(TIME * star_axis_speed * 1.3),
                          cos(TIME * star_axis_speed * 1.7));
        }
        
        // Apply the offset and wrap the UV coordinates.
        moving_uv += offset;
        moving_uv = fract(moving_uv);

        // Create a grid over the moving UV space.
        vec2 grid_uv = moving_uv * star_field_scale;
        vec2 id = floor(grid_uv);
        vec2 f = fract(grid_uv) - 0.5;  // Center each grid cell.
        
        // Loop over neighboring grid cells to ensure seamless transitions.
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec2 neighbor = vec2(float(i), float(j));
                vec2 cell_id = id + neighbor;
                
                // Determine a fixed random star position within this grid cell.
                vec2 star_pos = vec2(random(cell_id), random(cell_id * 1.3)) - 0.5;
                
                // Compute the distance from the fragment (within the cell) to the star.
                float d = length(f - star_pos);
                // Use smoothstep for soft star edges.
                float star = (1.0 - smoothstep(star_size * 0.5, star_size, d));
                star_accum += star;
            }
        }
        star_accum = clamp(star_accum, 0.0, 1.0);
    }

    // Blend the stars into the final color.
    final_color = mix(final_color, vec3(1.0), star_intensity * star_accum);
    
    // Output the final color with the original alpha
    COLOR = vec4(final_color, scene_color.a);
} 