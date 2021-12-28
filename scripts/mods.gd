extends Node


const MODS_PATH = "user://mods"

var next_mod = ""
var next_label = ""

var mods_info = {}


func _ready():
	if not Global.settings.has("active_mods"):
		Global.settings["active_mods"] = []
	for i in Global.settings["active_mods"]:
		if not load_mod(i):
			Global.settings["active_mods"].erase(i)
			Global.save_settings()


func get_inactive():
	var files = []
	var dir = Directory.new()
	if dir.dir_exists(MODS_PATH): # Check if mods folder exists
		dir.open(MODS_PATH) # Open folder
	else:
		dir.make_dir(MODS_PATH) # Create the mods folder
		dir.open(MODS_PATH) # Open folder
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "": # No more mods
			break
		elif not file.begins_with(".") and file.ends_with(".pck") and not Global.settings["active_mods"].has(file):
			files.append(file)
	dir.list_dir_end()
	return files


func get_active():
	return mods_info


func load_mod(filename: String) -> bool:
	var file = File.new()
	if file.file_exists(MODS_PATH + "/%s" % filename):
		ProjectSettings.load_resource_pack(MODS_PATH + "/%s" % filename)
		if file.file_exists("res://" + filename.replace(".pck", ".tscn")):
			if file.file_exists("res://" + filename.replace(".pck", ".json")):
				var mod_instance = load("res://" + filename.replace(".pck", ".tscn")).instance()
				file.open("res://" + filename.replace(".pck", ".json"), File.READ)
				var mod_manifest = parse_json(file.get_as_text())
				mods_info[filename] = mod_manifest
				call_deferred("add_mod", mod_instance)
				if mod_manifest.keys().has("name") and mod_manifest.keys().has("version"):
					print(mod_manifest["name"] + " successfully loaded, version " + mod_manifest["version"])
					return true
				else:
					print("could find mod scene but manifest was bad")
			else:
				print("could find mod scene but manifest was missing")
			file.close()
			return false
		else:
			file.close()
			return false
	else:
		return false


func activate_mod(filename: String) -> bool:
	if load_mod(filename):
		Global.settings["active_mods"].append(filename)
		Global.save_settings()
		return true
	else:
		return false


func deactivate_mod(filename: String):
	Global.settings["active_mods"].erase(filename)
	mods_info.erase(filename)
	Global.save_settings()


func add_mod(mod_instance: Node):
	get_tree().get_root().add_child(mod_instance)
