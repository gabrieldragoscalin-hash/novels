extends RefCounted
## Device-local persistence, not a cloud account. Only validated small integers load.
const PATH := "user://hub.json"
var storage_path := PATH
var keys := 0
var seals := 0
var training := 0
var persistence_ok := true
var enabled := true

func _init(persist: bool = true, save_path: String = PATH) -> void:
	storage_path = save_path
	enabled = persist
	if not enabled or not FileAccess.file_exists(storage_path): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
	if not data is Dictionary: return
	for name in ["keys", "seals", "training"]:
		var value = data.get(name, 0)
		if value is float or value is int:
			set(name, clampi(int(value), 0, 3 if name == "training" else 100000))

func save() -> bool:
	if not enabled: return true
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		persistence_ok = false
		return false
	file.store_string(JSON.stringify({"keys": keys, "seals": seals, "training": training}))
	file.close()
	persistence_ok = true
	return true

func train() -> bool:
	if keys <= 0 or training >= 3: return false
	keys -= 1
	training += 1
	save()
	return true
