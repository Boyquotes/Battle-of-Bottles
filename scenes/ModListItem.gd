extends PanelContainer


signal toggle_mod
signal remove_mod

var file_name = ""
var active = false


func set_mod_name(ui_name, new_file_name):
	name = new_file_name
	$HBoxContainer/VBoxContainer/ModName.text = ui_name
	file_name = new_file_name


func get_mod_name():
	return file_name


func set_mod_version(version: String):
	$HBoxContainer/VBoxContainer/HBoxContainer2/VersionLabel.show()
	$HBoxContainer/VBoxContainer/HBoxContainer2/Version.show()
	$HBoxContainer/VBoxContainer/HBoxContainer2/Version.text = version


func activate_label():
	active = true
	$default_background.hide()
	$active_background.show()


func deactivate_label():
	active = false
	$default_background.show()
	$active_background.hide()


func _on_select_pressed():
	if file_name != "":
		emit_signal("toggle_mod", file_name)


func _on_TextureButton_pressed():
	emit_signal("remove_mod", file_name)
