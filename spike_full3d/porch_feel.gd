extends Node
## Fight feel for the porch: sound, hit-stop, camera shake and knockback.
## Made by porch.gd (`Feel.make(scene, camera)`); porch.gd calls the hooks when a hit lands.
## Sounds are the main game's clips (assets/audio), copied into audio/.

const HIT_STOP := .07        ## real seconds the world freezes when a punch lands
const HIT_STOP_KO := .16
const SHAKE_HIT := .35       ## trauma added (0..1); the shake is trauma squared
const SHAKE_HURT := .55
const SHAKE_MAX_OFFSET := .22
const KNOCK_HIT := 4.2       ## m/s a landed punch pushes the foe back
const KNOCK_HURT := 3.0      ## m/s Duff is pushed back when he's hit
const KNOCK_DECAY := 14.0    ## m/s lost per second
const MUSIC_DB := -14.0

var camera: Camera3D
var trauma := 0.0
var knock := {}               ## CharacterBody3D -> Vector3 push velocity
var music: AudioStreamPlayer
var bed: AudioStreamPlayer  ## ambience loop (play_bed)
var pool: Array[AudioStreamPlayer] = []
var streams := {}
var stopping := false

static func make(scene: Node, cam: Camera3D) -> Node:
	var feel = (load("res://porch_feel.gd") as GDScript).new()
	feel.name = "Feel"
	feel.process_mode = Node.PROCESS_MODE_ALWAYS
	feel.camera = cam
	scene.add_child(feel)
	return feel

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = MUSIC_DB
	add_child(music)
	play_music("mus_edm_neighborhood")

func _stream(clip: String) -> AudioStream:
	if not streams.has(clip):
		var path := "res://audio/%s.wav" % clip
		if not ResourceLoader.exists(path):
			path = "res://audio/%s.ogg" % clip
		streams[clip] = load(path) if ResourceLoader.exists(path) else null
	return streams[clip]

func sfx(clip: String, pitch_jitter := .08, db := 0.0) -> void:
	var stream := _stream(clip)
	if stream == null:
		return
	for p in pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.volume_db = db
			p.play()
			return

func play_music(clip: String) -> void:
	var stream := _stream(clip)
	if stream == null or (music.stream == stream and music.playing):
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	music.stream = stream
	music.play()

func stop_music() -> void:
	music.stop()

## A looping ambience under the music (home: fridge hum, room tone, the TV next door). "" stops it.
func play_bed(clip: String, db := -14.0) -> void:
	if bed == null:
		bed = AudioStreamPlayer.new()
		add_child(bed)
	if clip == "":
		bed.stop()
		return
	var stream := _stream(clip)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	bed.stream = stream
	bed.volume_db = db
	bed.play()

## A landed punch: freeze a beat, shake, shove the foe away from Duff.
func landed(foe: CharacterBody3D, from: Vector3, ko := false) -> void:
	sfx("hit")
	push(foe, foe.position - from, KNOCK_HIT * (1.4 if ko else 1.0))
	add_trauma(SHAKE_HIT * (1.5 if ko else 1.0))
	hit_stop(HIT_STOP_KO if ko else HIT_STOP)
	if ko:
		sfx("sting_ko", 0.0, -2.0)

## Duff takes a hit.
func hurt(duff: CharacterBody3D, from: Vector3) -> void:
	sfx("hurt")
	push(duff, duff.position - from, KNOCK_HURT)
	add_trauma(SHAKE_HURT)
	hit_stop(HIT_STOP)

func push(body: CharacterBody3D, away: Vector3, speed: float) -> void:
	away.y = 0
	if away.length() < .01:
		return
	knock[body] = away.normalized() * speed

## Extra velocity for this body this frame (porch.gd adds it in _move).
func knock_of(body: CharacterBody3D) -> Vector3:
	return knock.get(body, Vector3.ZERO)

func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)

func hit_stop(seconds: float) -> void:
	if stopping:
		return
	stopping = true
	Engine.time_scale = .05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	stopping = false

## Slow motion for a counter (real seconds), after any hit-stop already running.
func slow_mo(seconds: float, scale := .35) -> void:
	while stopping:
		await get_tree().process_frame
	stopping = true
	Engine.time_scale = scale
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	stopping = false

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, .001)
	for body in knock.keys():
		var v: Vector3 = knock[body]
		var left := v.length() - KNOCK_DECAY * delta
		if left <= 0 or not is_instance_valid(body):
			knock.erase(body)
		else:
			knock[body] = v.normalized() * left
	trauma = maxf(0, trauma - 1.6 * real)
	if camera:
		var s := trauma * trauma * SHAKE_MAX_OFFSET
		camera.h_offset = randf_range(-s, s)
		camera.v_offset = randf_range(-s, s)

func _exit_tree() -> void:
	Engine.time_scale = 1.0  # a retry mid hit-stop must not leave the next scene frozen
