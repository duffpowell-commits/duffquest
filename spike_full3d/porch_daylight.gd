extends RefCounted
## Light that follows the in-game clock (Phase 2 step 3, Nov 25 2026). The HUD clock drives it:
## dawn, morning, noon, golden hour (the porch's signature look, Duff's pick), dusk and night.
## Each key is [minute of the day, sun pitch, sun yaw, sun colour, sun energy, sky fill colour,
## fill energy, background, lamp multiplier]. Between keys every value blends smoothly.
## `--clock=HH:MM` starts the HUD clock anywhere for renders and phone checks.

const KEYS := [
	[0,    -38.0, -40.0,  "#7d93ff", .22, "#3a4270", .48, "#1a1d34", 1.35],
	[330,  -38.0, -40.0,  "#7d93ff", .22, "#3a4270", .48, "#1a1d34", 1.35],  # 5:30 AM still night
	[390,  -8.0,  -112.0, "#ff9a7a", .75, "#9a8bb0", .52, "#6a5a7a", .7],    # 6:30 dawn
	[480,  -36.0, -100.0, "#ffe6c8", 1.25, "#cdd5ee", .62, "#8fa6c8", .18],  # 8:00 morning
	[720,  -62.0, -40.0,  "#fff4e4", 1.35, "#d8e0f0", .66, "#9db8d8", .1],   # noon
	[930,  -40.0, -50.0,  "#ffe2b8", 1.4, "#b9bede", .64, "#8a8fb0", .3],    # 3:30 PM
	[1050, -24.0, -62.0,  "#ffb06a", 1.55, "#8d93c4", .62, "#5a4a6a", 1.0],  # 5:30 PM golden hour
	[1170, -6.0,  -70.0,  "#ff7a5a", .6, "#5a5a90", .5, "#2e2a48", 1.25],    # 7:30 PM dusk
	[1260, -38.0, -40.0,  "#7d93ff", .22, "#3a4270", .48, "#1a1d34", 1.35],  # 9:00 PM night
	[1440, -38.0, -40.0,  "#7d93ff", .22, "#3a4270", .48, "#1a1d34", 1.35],
]

## Every light value for a minute of the day (wraps past midnight).
static func at(minute: float) -> Dictionary:
	var m := fposmod(minute, 1440.0)
	var i := 0
	while i < KEYS.size() - 2 and KEYS[i + 1][0] <= m:
		i += 1
	var a: Array = KEYS[i]
	var b: Array = KEYS[i + 1]
	var t := smoothstep(0.0, 1.0, (m - a[0]) / maxf(1.0, b[0] - a[0]))
	return {
		"sun_rot": Vector3(lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), 0),
		"sun_color": Color(a[3]).lerp(Color(b[3]), t),
		"sun_energy": lerpf(a[4], b[4], t),
		"fill": Color(a[5]).lerp(Color(b[5]), t),
		"fill_energy": lerpf(a[6], b[6], t),
		"sky": Color(a[7]).lerp(Color(b[7]), t),
		"lamp": lerpf(a[8], b[8], t),
	}

## "golden hour", "night"... for labels and tests.
static func phase(minute: float) -> String:
	var m := fposmod(minute, 1440.0)
	if m < 345 or m >= 1230:
		return "night"
	if m < 430:
		return "dawn"
	if m < 660:
		return "morning"
	if m < 990:
		return "afternoon"
	if m < 1125:
		return "golden hour"
	return "dusk"
