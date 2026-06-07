shader_type canvas_item;

uniform vec4 color: source_color = vec4(1.0);

uniform int pixels_to_check = 2;
uniform int center_distance_cap = 2;

bool has_neighbor(vec2 uv, vec2 texture_pixel_size, sampler2D sprite_texture) {
	for (int x = -pixels_to_check; x < pixels_to_check + 1; x += 1)
	{
		for (int y = -pixels_to_check; y < pixels_to_check + 1; y += 1)
		{
			if (x == 0 && y == 0) {
				continue;
			}

			if (abs(x) + abs(y) > center_distance_cap)
			{
				continue;
			}
			vec2 xy = vec2(float(x), float(y));

			vec2 sprite_coordinates = uv + xy * texture_pixel_size;

			if (texture(sprite_texture, sprite_coordinates).a > .0) {
				return true;
			}
		}
	}

	return false;
}

void fragment() {
	if (COLOR.a == .0 && has_neighbor(UV, TEXTURE_PIXEL_SIZE, TEXTURE))
	{
		COLOR =color;
	}
}
