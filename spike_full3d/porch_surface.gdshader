shader_type spatial;

uniform float grain = 0.18;
uniform vec3 grain_scale = vec3(20.0);
uniform bool lawn = false;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

float cell_hash(vec3 cell) {
	vec3 p = fract(cell * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 point) {
	vec3 cell = floor(point);
	vec3 weight = smoothstep(vec3(0.0), vec3(1.0), fract(point));
	vec4 lower = vec4(cell_hash(cell), cell_hash(cell + vec3(1, 0, 0)),
		cell_hash(cell + vec3(0, 1, 0)), cell_hash(cell + vec3(1, 1, 0)));
	cell.z += 1.0;
	vec4 upper = vec4(cell_hash(cell), cell_hash(cell + vec3(1, 0, 0)),
		cell_hash(cell + vec3(0, 1, 0)), cell_hash(cell + vec3(1, 1, 0)));
	vec4 plane = mix(lower, upper, weight.z);
	return mix(mix(plane.x, plane.y, weight.x), mix(plane.z, plane.w, weight.x), weight.y);
}

void fragment() {
	float broad = value_noise(local_position * 3.8);
	float fine = value_noise(local_position * grain_scale);
	vec3 base = COLOR.rgb;
	if (lawn) {
		float shade = value_noise(local_position * vec3(0.75, 1.0, 1.15));
		float exposed = smoothstep(0.51, 0.72, broad * 0.44 + shade * 0.56);
		float edges = smoothstep(1.82, 2.2, local_position.z)
			+ smoothstep(5.8, 6.9, abs(local_position.x));
		base = mix(base * vec3(0.80, 1.0, 0.81), vec3(0.34, 0.23, 0.14),
			clamp(exposed * 0.62 + edges * broad * 0.45, 0.0, 0.74));
	}
	ALBEDO = base * (1.0 + (fine - 0.5) * grain + (broad - 0.5) * grain * 0.72);
	ROUGHNESS = 0.92 - fine * 0.12;
}
