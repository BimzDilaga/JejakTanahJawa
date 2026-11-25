shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec3 tint = vec3(1.0);
uniform float exposure = 1.0;
uniform float saturation = 1.0;
uniform vec3 shadow_lift = vec3(0.0);
uniform float fire_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 fire_origin = vec2(0.65, 0.45);
uniform vec2 player_origin = vec2(0.4, 0.6);
uniform float night_strength : hint_range(0.0, 1.0) = 0.0;
uniform float fire_pulse = 1.0;

void fragment() {
	vec3 source = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float luminance = dot(source, vec3(0.2126, 0.7152, 0.0722));
	vec3 graded = mix(vec3(luminance), source, saturation) * tint * exposure;
	// Preserve shadow detail so night platforms and attack silhouettes stay readable.
	graded += shadow_lift * (1.0 - luminance);
	float focus_distance = length((SCREEN_UV-player_origin)*vec2(SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x,1.0));
	graded = mix(graded,source*vec3(0.82,0.91,1.04)+shadow_lift,exp(-focus_distance*8.0)*night_strength*0.16);
	// A restrained warm bias plus soft light around Banaspati, below the HUD.
	float distance_to_fire = length((SCREEN_UV-fire_origin) * vec2(SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x, 1.0));
	float warmth = fire_strength * (0.50 + 0.50 * exp(-distance_to_fire * 3.0));
	vec3 fire_grade = source * vec3(1.15, 0.72, 0.52) * 0.83;
	fire_grade += vec3(0.04, 0.012, 0.004) * (1.0-luminance);
	graded = mix(graded, fire_grade, warmth);
	graded += vec3(0.14, 0.028, 0.006) * exp(-distance_to_fire * 7.0) * fire_strength * fire_pulse;
	COLOR = vec4(clamp(graded, vec3(0.0), vec3(1.0)), 1.0);
}
