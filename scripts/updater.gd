extends CanvasLayer
## Autoload "Updater": in-app updates for the Android APK. Does nothing on web, desktop,
## headless tests and the editor (no build number there).
##
## CI stamps every APK with a counting build number (res://build_code.txt + Android
## version/code = the workflow run number) and on main uploads both Duff Quest editions plus version.json
## ({"code": N, "sha": "abc1234"}) to the repo's public "dev" release, version.json LAST.
## On launch and when the app comes back to the front this reads version.json; if its code
## is higher it offers UPDATE NOW, downloads the APK into user:// and hands it to Android's
## installer (OS.shell_open; Godot's FileProvider makes the content:// URI).
##
## Needs: REQUEST_INSTALL_PACKAGES + INTERNET in the Android preset, and every build signed
## with the SAME key (the keystone, signing/keystone.keystore.enc, unlocked by KEYSTONE_PASS).
## Off-phone check: UPDATER_TEST=1 UPDATER_CODE=1 UPDATER_URL=<json url> UPDATER_SHOT=<png>.

const RELEASE_URL := "https://github.com/duffpowell-commits/duffquest/releases/download/dev/"
const APK_PATH := "user://update.apk"
const RECHECK_S := 120.0

var my_code := 0
var new_code := 0
var busy := false
var last_check := -1e9
var http: HTTPRequest
var box: PanelContainer
var line: Label
var go_btn: Button
var installing := false


static func is_newer(remote: int, local: int) -> bool:
	return local > 0 and remote > local


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _enabled():
		return
	my_code = _local_code()
	if my_code <= 0:
		return
	if FileAccess.file_exists(APK_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(APK_PATH))
	var poll := Timer.new()
	poll.wait_time = RECHECK_S
	poll.timeout.connect(_check_if_due)
	add_child(poll)
	poll.start()
	await get_tree().create_timer(1.5).timeout
	check()


func _enabled() -> bool:
	return OS.get_environment("UPDATER_TEST") == "1" or OS.get_name() == "Android"


func _local_code() -> int:
	if OS.get_environment("UPDATER_CODE") != "":
		return OS.get_environment("UPDATER_CODE").to_int()
	if FileAccess.file_exists("res://build_code.txt"):
		return FileAccess.get_file_as_string("res://build_code.txt").strip_edges().to_int()
	return 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_check_if_due()


func _check_if_due() -> void:
	if my_code > 0 and box == null and Time.get_ticks_msec() / 1000.0 - last_check >= RECHECK_S:
		check()


func check() -> void:
	if busy:
		return
	busy = true
	last_check = Time.get_ticks_msec() / 1000.0
	var url := OS.get_environment("UPDATER_URL")
	if url == "":
		url = RELEASE_URL + "version.json"
	url += ("&" if "?" in url else "?") + "t=%d" % Time.get_unix_time_from_system()
	var req := _request()
	req.request_completed.connect(_on_version, CONNECT_ONE_SHOT)
	if req.request(url) != OK:
		busy = false


func _request() -> HTTPRequest:
	if http != null:
		http.queue_free()
	http = HTTPRequest.new()
	http.max_redirects = 8
	http.timeout = 20.0
	add_child(http)
	return http


func _on_version(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("code"):
		return
	new_code = int(data["code"])
	print("UPDATER mine %d, release %d" % [my_code, new_code])
	if is_newer(new_code, my_code):
		_offer()


func _offer() -> void:
	if box != null:
		return
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box = PanelContainer.new()
	center.add_child(box)
	var content := VBoxContainer.new()
	box.add_child(content)
	line = Label.new()
	line.text = "Build %d is available. You have build %d." % [new_code, my_code]
	content.add_child(line)
	go_btn = Button.new()
	go_btn.text = "UPDATE NOW"
	go_btn.custom_minimum_size.y = 40
	go_btn.pressed.connect(_go)
	content.add_child(go_btn)
	var later := Button.new()
	later.text = "LATER"
	later.custom_minimum_size.y = 40
	later.pressed.connect(_close)
	content.add_child(later)
	if OS.get_environment("UPDATER_SHOT") != "":
		await get_tree().create_timer(0.5).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("UPDATER_SHOT"))
		print("UPDATER SHOT")


func _close() -> void:
	installing = false
	if http != null and busy:
		http.cancel_request()
		busy = false
	box.get_parent().queue_free()
	box = null


func _apk_name() -> String:
	return "duffquest.apk" if OS.has_feature("family") else "duffquest-public.apk"


func _go() -> void:
	if installing:
		_install()
		return
	if busy:
		return
	busy = true
	go_btn.disabled = true
	line.text = "Downloading build %d..." % new_code
	var req := _request()
	req.timeout = 0.0
	req.download_file = APK_PATH
	req.request_completed.connect(_on_apk, CONNECT_ONE_SHOT)
	if req.request(RELEASE_URL + _apk_name() + "?t=%d" % Time.get_unix_time_from_system()) != OK:
		_failed()


func _process(_dt: float) -> void:
	if busy and box != null and http != null and http.download_file != "":
		var total := http.get_body_size()
		if total > 0:
			line.text = "Downloading build %d... %d%%" % [new_code, int(100.0 * http.get_downloaded_bytes() / total)]


func _on_apk(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	busy = false
	if box == null:
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_failed()
		return
	installing = true
	go_btn.disabled = false
	go_btn.text = "INSTALL"
	line.text = "Android will ask you to confirm. First time only: allow this app to install apps, then come back and tap INSTALL."
	_install()


func _install() -> void:
	if OS.shell_open(ProjectSettings.globalize_path(APK_PATH)) != OK:
		line.text = "Android wouldn't open the installer. Tap INSTALL to try again."


func _failed() -> void:
	busy = false
	go_btn.disabled = false
	line.text = "Download failed. Check your signal and tap UPDATE NOW again."
