shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float bloom_strength = 0.09;
uniform float focus_strength = 0.06;
void fragment() {
 vec2 uv = SCREEN_UV;
 vec2 p = SCREEN_PIXEL_SIZE * 2.0;
 vec3 sharp = texture(screen_texture, uv).rgb;
 vec3 soft = (texture(screen_texture,uv+vec2(p.x,0.0)).rgb + texture(screen_texture,uv-vec2(p.x,0.0)).rgb + texture(screen_texture,uv+vec2(0.0,p.y)).rgb + texture(screen_texture,uv-vec2(0.0,p.y)).rgb) * 0.25;
 // Almost imperceptible far-edge focus falloff; actors and the central view stay crisp.
 float far_edge = (1.0-smoothstep(0.0,0.18,uv.y)) * focus_strength;
 vec3 col = mix(sharp,soft,far_edge);
 vec3 bloom = max(soft-vec3(0.78),vec3(0.0)) * bloom_strength;
 col += bloom;
 float vignette = smoothstep(0.35,0.90,length((uv-vec2(0.5))*vec2(1.0,0.85)));
 col *= 1.0-vignette*0.12;
 COLOR = vec4(col,1.0);
}
