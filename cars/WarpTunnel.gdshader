shader_type spatial;
render_mode unshaded, cull_front, blend_add;


uniform sampler2D noise_texture;
uniform float warp_speed : hint_range(0.0, 10.0) = 0.0;
uniform vec4 streak_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);

void fragment() {
    vec2 moving_uv = UV;
    moving_uv.y -= TIME * (warp_speed * 5.0);

    float noise = texture(noise_texture, moving_uv).r;

    ALBEDO = streak_color.rgb;


    ALPHA = noise * clamp(warp_speed, 0.0, 1.0);
}