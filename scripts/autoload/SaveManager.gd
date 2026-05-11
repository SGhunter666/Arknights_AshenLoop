extends Node

const SAVE_PATH := "user://save_profile.json"
const TEMP_SAVE_PATH := "user://save_profile.json.tmp"
const BACKUP_SAVE_PATH := "user://save_profile.json.bak"

func save_profile(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_SAVE_PATH):
			dir.remove(BACKUP_SAVE_PATH.get_file())
		var backup_error: Error = dir.rename(SAVE_PATH.get_file(), BACKUP_SAVE_PATH.get_file())
		if backup_error != OK:
			dir.remove(TEMP_SAVE_PATH.get_file())
			return
	var save_error: Error = dir.rename(TEMP_SAVE_PATH.get_file(), SAVE_PATH.get_file())
	if save_error == OK:
		return
	if FileAccess.file_exists(BACKUP_SAVE_PATH) and not FileAccess.file_exists(SAVE_PATH):
		dir.rename(BACKUP_SAVE_PATH.get_file(), SAVE_PATH.get_file())

func load_profile() -> Dictionary:
	var profile_result: Dictionary = _try_load_profile_from_path(SAVE_PATH)
	if bool(profile_result.get("loaded", false)):
		return profile_result.get("profile", {})
	if FileAccess.file_exists(SAVE_PATH):
		var backup_result: Dictionary = _try_load_profile_from_path(BACKUP_SAVE_PATH)
		if bool(backup_result.get("loaded", false)):
			return backup_result.get("profile", {})
	return {}

func _try_load_profile_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"loaded": false, "profile": {}}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"loaded": false, "profile": {}}
	var txt: String = file.get_as_text()
	file.close()
	if txt.strip_edges().is_empty():
		return {"loaded": true, "profile": {}}
	var parser := JSON.new()
	var parse_error: Error = parser.parse(txt)
	if parse_error != OK:
		return {"loaded": false, "profile": {}}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"loaded": false, "profile": {}}
	return {"loaded": true, "profile": parsed}

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
