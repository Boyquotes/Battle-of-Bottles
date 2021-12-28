extends MarginContainer


const MODS_PATH = "user://mods"
const MOD_LIST_ITEM_SCENE = preload("res://scenes/ModListItem.tscn")

var next_mod = ""
var next_label = ""

onready var list_node = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/ScrollContainer/mods_list


func _ready():
	pass


func show_mods():
	for i in list_node.get_children():
		i.queue_free()
	
	var inactive = Mods.get_inactive()
	var active = Mods.get_active()
	
	if inactive.size() > 0 or active.size() > 0:
		$HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/no_mods.hide()
		if active.size() > 0:
			for i in active.keys():
				var mod_item_instance = MOD_LIST_ITEM_SCENE.instance()
				mod_item_instance.set_mod_name(active[i]["name"], i)
				mod_item_instance.set_mod_version(active[i]["version"])
				mod_item_instance.activate_label()
				mod_item_instance.connect("toggle_mod", self, "toggle_mod")
				list_node.add_child(mod_item_instance)
		if inactive.size() > 0:
			for i in inactive:
				var mod_item_instance = MOD_LIST_ITEM_SCENE.instance()
				mod_item_instance.set_mod_name(i, i)
				mod_item_instance.connect("toggle_mod", self, "toggle_mod")
				list_node.add_child(mod_item_instance)
	else:
		$HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/no_mods.show()


func toggle_mod(file_name):
	if not Global.settings["active_mods"].has(file_name):
		next_mod = file_name
		$warning.show()
	else:
		Mods.deactivate_mod(file_name)
		show_mods()


func _on_Continue_pressed():
	Mods.activate_mod(next_mod)
	$warning.hide()
	show_mods()


func _on_Cancel_pressed():
	$warning.hide()


func _on_BackMods_pressed():
	pass


func _on_no_mods_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://mods"))
