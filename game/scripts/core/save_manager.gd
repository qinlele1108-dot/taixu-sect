extends Node

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame.backup.json"
const SETTINGS_PATH := "user://settings.json"

func save_data(data: Dictionary) -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true

func load_data() -> Dictionary:
	var primary := _read_json(SAVE_PATH)
	if not primary.is_empty():
		return primary
	return _read_json(BACKUP_PATH)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func reset_save() -> void:
	for path in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

