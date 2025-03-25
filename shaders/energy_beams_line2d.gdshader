/*
Modified from Godot Shaders - the free shader library.
godotshaders.com/shader/energy-beams

Adapted to work with Line2D nodes instead of rectangular areas.
*/

shader_type canvas_item;
render_mode blend_add;

uniform float energy = 3.0; // How much the beams will travel perpendicular to the line
uniform int roughness : hint_range(1, 10) = 3; // How compact the noise texture will be
uniform int frequency = 10; // Amount of "ripples" in the beams

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

void fragment() {
    // For Line2D:
    // UV.x is position along the line (0 to 1)
    // UV.y is position perpendicular to the line (-0.5 to 0.5)
    
    // Use position along the line for animation
    float along_line = UV.x;
    // Use the perpendicular value for the beam effect
    float perp_line = UV.y + 0.5; // Convert from -0.5-0.5 to 0-1 range
    
    // Create cloud texture for beam effect
    vec4 clouds = vec4(fbm(vec2(along_line * 3.0, perp_line), TIME * speed));
    vec4 diff_clouds = difference(clouds, vec4(perp_line - 0.5 + (perp_line * 0.02 * energy * progress)));
    
    // Create beam with proper thickness
    float beam_thickness = thickness * progress;
    vec4 beam = clamp(smoothstep(0.5 - beam_thickness, 0.5 - beam_thickness + 0.005 * progress, 1.0 - diff_clouds), vec4(0.0), vec4(1.0));
    
    // Create outline
    float outline = 0.5 - beam_thickness - (outline_thickness * progress);
    vec4 beam_outline = clamp(smoothstep(outline, outline + 0.04, 1.0 - diff_clouds), 0.0, 1.0);
    beam_outline = clamp(beam_outline - beam, 0.0, 1.0);
    
    // Final color
    COLOR = (beam * (color + vec4(glow, glow, glow, 0.0))) + 
            (beam_outline * (outline_color + vec4(outline_glow, outline_glow, outline_glow, 0.0)));
} 