shader_type spatial;
// Nov 19: the 3D view's standing cards (characters, trees, street props) as rounded cut-outs instead of stickers.
// view3d.gd puts this on a card's material_override (Sprite3D then no longer binds its texture: `tex` is set by
// hand). The card's silhouette is its height map: alpha read from a blurrier mip, so the edges roll off like a
// pillow and the sun / street lamps / door pools shade one side and light the other. No extra textures to download.
// Trees bend from the top in the wind (`sway` > 0). Off in Lite (cards keep the plain Sprite3D material).
render_mode depth_draw_opaque, cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform float bevel = 1.0;        // how round the cut-out reads (0 = flat card)
uniform float spread = 3.0;       // texels between height samples (bigger = softer, wider roll-off)
uniform float sway = 0.0;         // wind bend at the top of the card, metres (trees)
uniform float sway_phase = 0.0;
uniform float wind = 1.0;         // gust strength (weather)
uniform float card_h = 1.0;       // card height in metres (sway scales with it)

void vertex() {
	if (sway > 0.0) {
		// UV.y = 0 at the top of the art, 1 at its feet: the trunk stays put, the crown leans
		float up = clamp(1.0 - UV.y, 0.0, 1.0);
		float t = TIME * 1.3 + sway_phase;
		float gust = sin(t) * 0.7 + sin(t * 2.3 + 1.7) * 0.3;
		VERTEX.x += gust * sway * wind * up * up;
	}
}

void fragment() {
	vec4 c = texture(tex, UV) * COLOR;
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	if (bevel > 0.0) {
		vec2 ts = vec2(1.0) / vec2(textureSize(tex, 0));
		vec2 o = ts * spread;
		float lod = 2.0;
		float l = textureLod(tex, UV - vec2(o.x, 0.0), lod).a;
		float r = textureLod(tex, UV + vec2(o.x, 0.0), lod).a;
		float u = textureLod(tex, UV - vec2(0.0, o.y), lod).a;
		float d = textureLod(tex, UV + vec2(0.0, o.y), lod).a;
		// a mirrored card (flip_h) runs its UVs right-to-left on screen: turn the slope round with it
		float fx = dFdx(UV.x) < 0.0 ? -1.0 : 1.0;
		vec2 g = vec2((l - r) * fx, (u - d)) * bevel;
		NORMAL_MAP = normalize(vec3(g.x, -g.y, 1.0)) * 0.5 + 0.5;
	}
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
}
