shader_type spatial;
// Nov 19: soft contact shadow on the ground (view3d.gd _ao): a rounded rectangle `extent` metres each way that fades
// to nothing over `fall` metres. Stands in for ambient occlusion (the Compatibility renderer has no SSAO): the dark
// skirt where a wall, a tree or a bench meets the street.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec2 extent = vec2(1.0, 1.0);
uniform float fall = 0.5;
uniform float strength = 0.45;

void fragment() {
	vec2 size = (extent + vec2(fall)) * 2.0;
	vec2 p = (UV - 0.5) * size;
	vec2 q = abs(p) - extent;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);   // signed distance to the rect, metres
	float a = 1.0 - smoothstep(0.0, fall, d);
	ALBEDO = vec3(0.04, 0.03, 0.06);
	ALPHA = a * a * strength;
}
