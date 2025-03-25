/*
Modified energy beam shader that lets you specify start and end points.
Use this on a ColorRect that covers the area where you want the beam to appear.
*/

shader_type canvas_item;
render_mode blend_add;

// Beam endpoints (in UV space 0-1)
uniform vec2 start_point = vec2(0.2, 0.5);
uniform vec2 end_point = vec2(0.8, 0.5);
uniform float beam_width = 0.05; // Width of the beam

// Energy beam parameters
uniform float energy = 3.0; // How much the beams will distort
uniform int roughness : hint_range(1, 10) = 3; // How compact the noise texture will be
uniform int frequency = 10; // Amount of "ripples" in the beams
uniform float opacity : hint_range(0.0, 1.0) = 1.0; // Overall opacity of the beam

uniform float speed = 1.0; // Animation speed
uniform float thickness : hint_range(0.0, 0.1) = 0.006; // Thickness of the main beam
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.03; // Thickness of the outline color

uniform float glow : hint_range(0.0, 3.0) = 0.0; // Use together with WorldEnvironment's Glow feature
uniform float outline_glow : hint_range(0.0, 3.0) = 0.0;

uniform vec4 color : source_color = vec4(0.91, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.5, 1.0, 0.96, 1.0);

uniform float progress : hint_range(0.0, 1.0) = 1.0;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) *
            43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    // Four corners in 2D of a tile
    float a = random(uv_index);
    float b = random(uv_index + vec2(1.0, 0.0));
    float c = random(uv_index + vec2(0.0, 1.0));
    float d = random(uv_index + vec2(1.0, 1.0));

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix(a, b, blur.x) +
            (c - a) * blur.y * (1.0 - blur.x) +
            (d - b) * blur.x * blur.y;
}

float fbm(vec2 uv, float time) {
    int octaves = roughness;
    float amp = 0.01 * energy * progress;
    float freq = float(frequency);
    float value = 0.0;
    
    for(int i = 0; i < octaves; i++) {
        value += amp * noise(freq * vec2(uv.x, uv.y + time));
        amp *= 0.5;
        freq *= 2.0;
    }
    return value;
}

vec4 difference(vec4 base, vec4 blend){
    return abs(base - blend);
}

// Calculate distance from point to line segment
float distToLineSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    vec2 closest = a + t * ba;
    return length(p - closest);
}

// Project point onto line segment and get normalized position along line (0-1)
float projectedPosition(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return t;
}

void fragment() {
    // Initialize alpha to 0 (transparent)
    COLOR = vec4(0.0);
    
    // Calculate distance from current pixel to beam line
    float dist = distToLineSegment(UV, start_point, end_point);
    
    // Only process pixels within the beam width
    if (dist <= beam_width) {
        // Calculate position along beam (0 = start_point, 1 = end_point)
        float beam_pos = projectedPosition(UV, start_point, end_point);
        
        // Calculate normalized perpendicular distance (0 = center, 1 = edge)
        float perp_dist = dist / beam_width;
        
        // Create animated noise value for the beam
        float noise_value = fbm(vec2(beam_pos * 5.0, perp_dist * 3.0), TIME * speed);
        
        // Calculate beam and outline intensities
        float beam_center = 1.0 - smoothstep(0.0, thickness, perp_dist + noise_value * energy * 0.1);
        float beam_outline = 1.0 - smoothstep(thickness, thickness + outline_thickness, perp_dist + noise_value * energy * 0.1);
        
        // Calculate the final color
        vec3 final_color = color.rgb * beam_center + outline_color.rgb * (beam_outline - beam_center);
        float final_alpha = max(beam_center, beam_outline) * progress * opacity;
        
        // Add glow
        final_color += glow * color.rgb * beam_center + outline_glow * outline_color.rgb * (beam_outline - beam_center);
        
        // Set the output color
        COLOR = vec4(final_color, final_alpha);
    }
} 