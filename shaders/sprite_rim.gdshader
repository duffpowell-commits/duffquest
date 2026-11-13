// Rim light for character sheets: opaque sprite pixels whose neighbour toward the light is empty pick up the
// scene's light colour, so a character reads as lit by the room instead of pasted on. Soft or faded draws
// (shadows, dash ghosts, hurt flash) and untextured shapes are left alone. Uniforms are set every frame by
// hd_presentation.gd through Art.rim_material().
shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.6, 1.0);
uniform vec2 light_dir = vec2(-0.45, -0.9);   // toward the light, screen space
uniform float strength = 0.6;
uniform float shade = 0.18;                    // darken the edge facing away from the light

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 c = COLOR;   // Godot 4: already texture * modulate
	if (tex.a > 0.99 && c.a > 0.95 && strength > 0.0) {
		// 2x sheets (512 px) get a 2-texel step so the rim is the same width on screen as on 1x sheets
		vec2 px = TEXTURE_PIXEL_SIZE * max(1.0, floor(float(textureSize(TEXTURE, 0).x) / 400.0));
		vec2 d = normalize(light_dir);
		float lit = (1.0 - texture(TEXTURE, UV + d * px).a)
			+ 0.5 * (1.0 - texture(TEXTURE, UV + d * px * 2.0).a);
		float away = 1.0 - texture(TEXTURE, UV - d * px).a;
		lit = clamp(lit, 0.0, 1.0);
		vec3 rim = c.rgb + rim_color.rgb * 0.75 * (1.0 - c.rgb * 0.5);
		c.rgb = mix(c.rgb, rim, lit * strength);
		c.rgb *= 1.0 - away * shade * strength;
	}
	COLOR = c;
}
