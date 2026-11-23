extends Node
## Prepare the normal entry scene while the publisher card is visible.

@export_file("*.tscn") var entry_scene: String


func _ready() -> void:
	var loading := ResourceLoader.load_threaded_request(entry_scene, "PackedScene")
	if not $StudioSplash.finished:
		await $StudioSplash.dismissed

	if loading == OK:
		while ResourceLoader.load_threaded_get_status(entry_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(entry_scene) == ResourceLoader.THREAD_LOAD_LOADED:
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(entry_scene))
			return
	get_tree().change_scene_to_file(entry_scene)
