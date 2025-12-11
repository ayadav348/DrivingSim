shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float blur_strength : hint_range(0.0, 0.1) = 0.0;


const int SAMPLES = 10;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 uv = SCREEN_UV - center;
	vec3 color = vec3(0.0);
	float total = 0.0;


	for(int i = 0; i < SAMPLES; i++) {
		float scale = 1.0 - blur_strength * (float(i) / float(SAMPLES));
		color += texture(screen_texture, center + uv * scale).rgb;
		total += 1.0;
	}

	COLOR.rgb = color / total;
}