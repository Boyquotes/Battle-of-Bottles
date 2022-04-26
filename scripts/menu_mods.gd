extends MarginContainer


const MODS_PATH = "user://mods"
const MOD_LIST_ITEM_SCENE = preload("res://scenes/ModListItem.tscn")

var next_mod = ""
var next_label = ""
var current_thread: Thread

onready var list_node = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/ScrollContainer/mods_list
onready var loading = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/loading


func _ready():
	get_tree().connect("files_dropped", self, "_on_files_dropped")


func _process(delta):
	if loading.visible:
		loading.get_node("spinner_anchor/Sprite").rotation_degrees += delta * get_parent().LOADING_SPINNER_SPEED


func _on_files_dropped(files, _screen):
	if visible:
		if current_thread == null:
			current_thread = Thread.new()
		else:
			current_thread.wait_to_finish()

		current_thread.start(self, "copy_mod", files)


func copy_mod(files):
	var d = Directory.new()
	call_deferred("start_loading")
	for i in files:
		if i.get_extension() == "pck":
			d.copy(i, Mods.MODS_PATH + "/" + i.get_file())
	call_deferred("stop_loading")
	return


func start_loading():
	hide_mods()
	loading.show()


func stop_loading():
	show_mods()
	loading.hide()


func show_mods():
	hide_mods()
	
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


func hide_mods():
	$HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/no_mods.hide()
	for i in list_node.get_children():
		i.queue_free()


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

func _exit_tree():
	current_thread.wait_to_finish()
