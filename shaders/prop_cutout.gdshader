shader_type canvas_item;
void fragment() {
	vec4 source = COLOR;
	// Suppress only near-transparent generation fringe; keep original PNG alpha intact.
	source.a *= smoothstep(0.08,0.28,source.a);
	COLOR = source;
}
