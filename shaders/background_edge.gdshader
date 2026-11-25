shader_type canvas_item;
uniform float fade_left = 0.0;
void fragment() {
	vec4 source = COLOR;
	source.a *= 1.0-smoothstep(0.76,0.94,UV.y);
	if (fade_left>0.0) source.a *= smoothstep(0.0,fade_left,UV.x);
	COLOR = source;
}
