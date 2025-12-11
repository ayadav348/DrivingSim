shader_type canvas_item;

// This binds the screen texture so we can read it
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// How much to stretch (0.0 is no effect, 0.05 is fast, 0.1 is extreme)
uniform float blur_strength : hint_range(0.0, 0.1) = 0.0;

// Iterations determine quality vs performance. 
// 10 is fast, 30 is smoother but costs more GPU.
const int SAMPLES = 10;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 uv = SCREEN_UV - center;
	vec3 color = vec3(0.0);
	float total = 0.0;
	
	// We sample the texture multiple times, stepping slightly closer 
	// to the center each time, creating a trail/stretch effect.
	for(int i = 0; i < SAMPLES; i++) {
		float scale = 1.0 - blur_strength * (float(i) / float(SAMPLES));
		color += texture(screen_texture, center + uv * scale).rgb;
		total += 1.0;
	}
	
	COLOR.rgb = color / total;
}