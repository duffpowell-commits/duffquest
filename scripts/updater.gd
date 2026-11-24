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
const UiStyle := preload("res://scripts/ui_style.gd")
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
## Build the player said LATER to. Why (Nov 23 review): LATER has to hold; the open-app poll
## re-offered the same build every 2 minutes, mid-fight included. Holds until the app restarts.
var dismissed := 0


static func is_newer(remote: int, local: int) -> bool:
	return local > 0 and remote > local


## Offer only a newer build the player hasn't already put off.
static func should_offer(remote: int, local: int, put_off: int) -> bool:
	return is_newer(remote, local) and remote > put_off


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
	await get_tree().create_timer(1.5).timeout
	check()
	# Why 30 s (Nov 23 review): a 120 s timer against the 120 s gate skipped every other tick.
	var poll := Timer.new()
	poll.wait_time = 30.0
	poll.timeout.connect(_on_poll)
	add_child(poll)
	poll.start()


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
		# Why (Nov 23 re-review): DuffQuest doesn't pause on focus-out, so a resume mid-fight
		# waits for the title like the poll does.
		if not _in_play():
			_check_if_due()


## Why (Nov 23 review): the sheet blocks every touch and doesn't pause the game, so the open-app
## poll and resume checks wait for the title screen or a pause. The launch check still runs.
func _on_poll() -> void:
	if not _in_play():
		_check_if_due()


func _in_play() -> bool:
	if get_tree().paused:
		return false
	var scene := get_tree().current_scene
	return scene != null and "in_title" in scene and not scene.in_title


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
	# Why (Nov 23 re-review): any reply (launch included) can land after the player left the title.
	if _in_play():
		return
	if should_offer(new_code, my_code, dismissed):
		_offer()


func _offer() -> void:
	if box != null:
		return
	# Why this look (Nov 23 review): the first-install line was clipped off a 640-wide screen and
	# the buttons ignored the MAIN/ALT roles and the 8-unit touch gap (CLAUDE.md hard rules).
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.INK, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	dim.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", _style(UiStyle.PANEL, 16))
	center.add_child(box)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	box.add_child(content)
	var head := _label("UPDATE AVAILABLE", 22, UiStyle.GOLD)
	head.add_theme_font_override("font", UiStyle.display)
	content.add_child(head)
	line = _label("Build %d is available. You have build %d." % [new_code, my_code], 16, UiStyle.CREAM)
	content.add_child(line)
	go_btn = _button("UPDATE NOW", UiStyle.BTN_MAIN)
	go_btn.pressed.connect(_go)
	content.add_child(go_btn)
	var later := _button("LATER", UiStyle.BTN_ALT)
	later.pressed.connect(_close)
	content.add_child(later)
	if OS.get_environment("UPDATER_SHOT") != "":
		await get_tree().create_timer(0.5).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("UPDATER_SHOT"))
		print("UPDATER SHOT")


func _close() -> void:
	dismissed = new_code
	installing = false
	if http != null and busy:
		http.cancel_request()
		busy = false
	box.get_parent().get_parent().queue_free()
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


func _style(fill: Color, pad: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = UiStyle.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(pad)
	return sb


func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 380
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", UiStyle.INK)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(text: String, role: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(380, 44)
	b.add_theme_font_override("font", UiStyle.display)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", UiStyle.CREAM)
	b.add_theme_color_override("font_outline_color", UiStyle.INK)
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_stylebox_override("normal", _style(role, 6))
	b.add_theme_stylebox_override("hover", _style(role.lightened(0.1), 6))
	b.add_theme_stylebox_override("pressed", _style(role.darkened(0.15), 6))
	b.add_theme_stylebox_override("disabled", _style(role.darkened(0.4), 6))
	return b
