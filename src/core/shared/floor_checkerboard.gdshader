shader_type spatial;
render_mode unshaded;

uniform float cell_size = 2.0;
uniform vec4 dark_tile : source_color = vec4(0.220, 0.265, 0.340, 1.0);
uniform vec4 light_tile : source_color = vec4(0.295, 0.345, 0.420, 1.0);
uniform vec4 grid_line : source_color = vec4(0.140, 0.180, 0.240, 1.0);
uniform float grid_line_width = 0.05;
uniform vec4 void_color : source_color = vec4(0.039, 0.071, 0.125, 1.0);
uniform float fade_start = 0.80;
uniform float fade_end = 1.00;
uniform sampler2D floor_texture : source_color;

void fragment() {
	// UV (0..1) per face. Since BoxMesh UV starts at bottom-left of each face,
	// UV * (mesh_size / cell_size) gives tile coordinate within the face.
	vec2 tile_coord = UV * (vec2(1.0) / vec2(cell_size));

	// Checkerboard: even-sum tiles = dark, odd-sum = light
	float is_light = mod(floor(tile_coord.x) + floor(tile_coord.y), 2.0);
	vec4 base_color = mix(dark_tile, light_tile, is_light);

	// Grid line: darken the tile edges to simulate a gap between blocks
	vec2 tile_frac = fract(tile_coord);
	float line_x = step(tile_frac.x, grid_line_width) + step(1.0 - grid_line_width, tile_frac.x);
	float line_z = step(tile_frac.y, grid_line_width) + step(1.0 - grid_line_width, tile_frac.y);
	float is_grid = clamp(line_x + line_z, 0.0, 1.0);

	ALBEDO = mix(base_color.rgb, grid_line.rgb, is_grid);

	// Apply floor texture if available
	if (texture(floor_texture, UV).a > 0.0) {
		ALBEDO = mix(ALBEDO, texture(floor_texture, UV).rgb, 0.6);
	}

	// Edge-fade to void: radial distance from UV center (mesh center).
	// Radial fade means the gradient is always world-space centered regardless of mesh aspect ratio.
	// Fade region is proportional to UV space, so it scales naturally with floor size.
	float d = length(UV - vec2(0.5));
	float fade = smoothstep(fade_end, fade_start, d);
	ALBEDO = mix(void_color.rgb, ALBEDO, fade);
}
