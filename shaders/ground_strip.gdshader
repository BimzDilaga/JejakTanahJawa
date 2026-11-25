shader_type canvas_item;
// Keep grass at its native proportions, then extend only the underground soil.
uniform vec2 strip_size = vec2(1280.0, 400.0);
uniform float world_x = 0.0;
void fragment() {
	vec2 at = UV * strip_size;
	float tile_x = (at.x + world_x) / (2172.0 * 0.65);
	float u = 1.0 - abs(mod(tile_x, 2.0) - 1.0);
	float source_y = 520.0 + at.y / 0.65;
	if (source_y > 724.0) {
		float band = (source_y - 724.0) / 84.0;
		source_y = 724.0 - (1.0 - abs(mod(band, 2.0) - 1.0)) * 84.0;
	}
	vec2 source_uv = vec2(clamp(u, 0.5/2172.0, 1.0-0.5/2172.0), clamp(source_y/724.0, 0.0, 1.0-0.5/724.0));
	COLOR = texture(TEXTURE, source_uv);
}
