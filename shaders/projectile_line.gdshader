shader_type canvas_item;

uniform sampler2D line_texture;
uniform float spacing : hint_range(0.1, 10.0) = 1.0;
uniform float speed : hint_range(-10.0, 10.0) = 1.0;

void fragment() {
    vec2 uv_scaled = UV;
    uv_scaled.x *= spacing; // Control texture repetition along the X-axis
    uv_scaled.x += TIME * speed; // Animate the texture along the X-axis
    COLOR = texture(line_texture, uv_scaled);
}