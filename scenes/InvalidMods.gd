extends Control


onready var error = $MarginContainer/VBoxContainer/loading_text


func _ready():
	Multiplayer.stop_multiplayer()
	$Timer.connect("timeout", self, "timeout")
	$Timer.start()
	if Global.required_mods.size() > 0:
		error.text = "The server requires the following mods:"
		for i in Global.required_mods:
			error.text += " " + i
		error.text += "\nInstalled:"
		if Mods.get_active().keys().size() > 0:
			for i in Mods.get_active().keys():
				error.text += " " + i
		else:
			error.text += " none"
	else:
		error.text = "Please disable all mods before connecting to this server."


func timeout():
	get_tree().change_scene("res://Menu.tscn")
