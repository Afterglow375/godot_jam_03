shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float spread : hint_range(0.0, 1.0) = 0.5;
uniform float cutoff : hint_range(-1.0, 1.0) = 0.1;
uniform float falloff : hint_range(0.0, 1.0) = 0.2;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.15;
uniform float outer_edge_fade : hint_range(0.0, 1.0) = 0.3;
uniform float ray_length_variation : hint_range(0.0, 1.0) = 0.5; // Controls how much ray length varies

uniform float speed = 1.0;
uniform float ray1_density = 8.0;
uniform float ray2_density = 30.0;
uniform float ray2_intensity : hint_range(0.0, 1.0) = 0.3;

uniform vec4 color : source_color = vec4(1.0, 0.9, 0.65, 0.8);

uniform bool hdr = false;
uniform float seed = 5.0;

// Random and noise functions from Book of Shader's chapter on Noise.
float random(vec2 _uv) {
	return fract(sin(dot(_uv.xy,
						 vec2(12.9898, 78.233))) *
		43758.5453123);
}

float noise(in vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);

	// Four corners in 2D of a tile
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));

	// Smooth Interpolation
	vec2 u = f * f * (3.0-2.0 * f);

	// Mix 4 corners percentages
	return mix(a, b, u.x) +
			(c - a)* u.y * (1.0 - u.x) +
			(d - b) * u.x * u.y;
}

vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

vec4 add(vec4 base, vec4 blend){
	return base + blend;
}

void fragment()
{
	// Convert UV to polar coordinates
	vec2 center = vec2(0.5, 0.5);
	vec2 relative_pos = UV - center;
	float angle = atan(relative_pos.y, relative_pos.x);
	float radius = length(relative_pos);
	
	// Get a random value based on the angle to vary ray length
	float angle_noise = noise(vec2(angle * 10.0 + seed, seed));
	
	// Create two different ray patterns
	vec2 ray1 = vec2(angle * ray1_density + sin(TIME * 0.1 * speed) * (ray1_density * 0.2) + seed, radius);
	vec2 ray2 = vec2(angle * ray2_density + sin(TIME * 0.2 * speed) * (ray1_density * 0.2) + seed, radius);
	
	// Cut off the ray's edges based on radius
	float cut = step(cutoff, radius) * step(radius, 1.0 - cutoff);
	ray1 *= cut;
	ray2 *= cut;
	
	// Apply the noise pattern (i.e. create the rays)
	float rays;
	
	if (hdr){
		// This is not really HDR, but check this to not clamp the two merged rays making 
		// their values go over 1.0. Can make for some nice effect
		rays = noise(ray1) + (noise(ray2) * ray2_intensity);
	}
	else{
		rays = clamp(noise(ray1) + (noise(ray2) * ray2_intensity), 0., 1.);
	}
	
	// Fade in at the inner edge
	rays *= smoothstep(0.0 + cutoff, edge_fade + cutoff, radius); // Inner edge
	
	// Apply variable-length ray fading based on angle
	float max_radius = 0.5; // Base maximum radius
	
	// Calculate varying max radius based on the angle noise
	float varied_max_radius = max_radius * (1.0 + ray_length_variation * (angle_noise - 0.5) * 2.0);
	
	// Calculate distance from current radius to the varied max radius
	float edge_dist = varied_max_radius - radius;
	
	// Apply smooth fade out with varying edge distances
	rays *= smoothstep(0.0, outer_edge_fade * varied_max_radius, edge_dist);
	
	// Color to the rays
	vec3 shine = vec3(rays) * color.rgb;

	// Using "Add" blend mode:
	shine = add(texture(SCREEN_TEXTURE, SCREEN_UV), vec4(shine, rays * color.a)).rgb;
	
	COLOR = vec4(shine, rays * color.a);
}
