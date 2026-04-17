extends Node

const SAVE_PATH := "user://save_profile.json"

func save_profile(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_profile() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var txt: String = file.get_as_text()
	file.close()
	if txt.strip_edges().is_empty():
		return {}
	var parser := JSON.new()
	var parse_error: Error = parser.parse(txt)
	if parse_error != OK:
		return {}
	var parsed: Variant = parser.data
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func update_profile(patch: Dictionary) -> void:
	var profile: Dictionary = load_profile()
	for key in patch.keys():
		profile[key] = patch[key]
	save_profile(profile)

func remove_profile_key(key: String) -> void:
	var profile: Dictionary = load_profile()
	if profile.has(key):
		profile.erase(key)
	save_profile(profile)
