shader_type canvas_item;
// Nov 17 diorama look for the 3D view (view3d.gd puts this on its SubViewportContainer, so only the 3D frame is
// blurred, never the HUD): a sharp band around Duff, soft top and bottom, like a photo of a miniature model.
// Compatibility renderer has no depth of field, so this is a screen-space blur that grows with distance from the band.
uniform float focus_y = 0.58;   // where Duff stands on screen (fraction of height)
uniform float band = 0.28;      // half-height of the sharp band (IGN v5: 0.24 blurred the storefronts at the top)
uniform float radius = 1.7;     // blur at the edges, in render pixels per unit scale
uniform float boost = 1.06;     // a touch more saturation in the band (toy-like)
void fragment() {
	float d = clamp((abs(UV.y - focus_y) - band) / (0.5 - band), 0.0, 1.0);
	d = d * d;
	vec2 px = TEXTURE_PIXEL_SIZE * radius * d * 2.0;
	vec4 c = texture(TEXTURE, UV) * 0.2;
	c += texture(TEXTURE, UV + vec2(px.x, 0.0)) * 0.1;
	c += texture(TEXTURE, UV - vec2(px.x, 0.0)) * 0.1;
	c += texture(TEXTURE, UV + vec2(0.0, px.y)) * 0.1;
	c += texture(TEXTURE, UV - vec2(0.0, px.y)) * 0.1;
	c += texture(TEXTURE, UV + px * 0.7) * 0.1;
	c += texture(TEXTURE, UV - px * 0.7) * 0.1;
	c += texture(TEXTURE, UV + vec2(px.x, -px.y) * 0.7) * 0.1;
	c += texture(TEXTURE, UV + vec2(-px.x, px.y) * 0.7) * 0.1;
	vec3 g = vec3(dot(c.rgb, vec3(0.299, 0.587, 0.114)));
	c.rgb = mix(g, c.rgb, mix(boost, 1.0, d));
	COLOR = c;
}
