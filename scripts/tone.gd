extends RefCounted

const RATE: = 22050
static var _cache: Dictionary = {}

static func freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

static func stream(midi: int, secs: float = 0.45, vol: float = 0.22) -> AudioStreamWAV:
	var key: = "%d_%.2f" % [midi, secs]
	if _cache.has(key):
		return _cache[key]
	var n: = int(RATE * secs)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var f: = freq(midi)
	for i in n:
		var t: = float(i) / RATE
		var ph: = fmod(t * f, 1.0)
		var tri: = 4.0 * absf(ph - 0.5) - 1.0
		var sq: = 1.0 if ph < 0.5 else -1.0
		var env: = minf(1.0, t * 200.0) * exp(-t * 5.0)
		var s: = (0.7 * tri + 0.3 * sq) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var w: = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	_cache[key] = w
	return w

static func noise(secs: float = 0.25, vol: float = 0.15) -> AudioStreamWAV:

	var key: = "noise_%.2f" % secs
	if _cache.has(key):
		return _cache[key]
	var rng: = RandomNumberGenerator.new()
	rng.seed = 99
	var n: = int(RATE * secs)
	var data: = PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t: = float(i) / RATE
		var s: = rng.randf_range(-1.0, 1.0) * exp(-t * 14.0) * vol
		data.encode_s16(i * 2, int(s * 32767.0))
	var w: = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	_cache[key] = w
	return w
