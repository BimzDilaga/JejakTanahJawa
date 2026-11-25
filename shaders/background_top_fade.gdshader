shader_type canvas_item;
void fragment() {
	vec4 pixel = texture(TEXTURE,UV);
	pixel.a *= smoothstep(0.0,0.12,UV.y);
	COLOR = pixel;
}
