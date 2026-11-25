// Thin ink outline (inverted hull), same width on screen at any distance; next_pass on the fighters.
// From the Devil You Owe (hunter) shaders. Works on skinned meshes.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 color : source_color = vec4(0.04, 0.03, 0.05, 1.0);
uniform float width_px = 3.0;   // outline width in screen pixels

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n_view = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec2 n_clip = (PROJECTION_MATRIX * vec4(n_view, 0.0)).xy;
	if (length(n_clip) > 0.0001) {
		clip.xy += normalize(n_clip) * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = color.rgb;
}
