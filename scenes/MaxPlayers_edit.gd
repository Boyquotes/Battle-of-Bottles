extends Panel


var current_edit
var value

onready var edit = $HBoxContainer/MaxPlayers


func _ready():
	value = int(edit.text)


func _on_left_pressed():
	if not int(edit.text) < 3:
		value = int(edit.text) - 1
		edit.text = str(value)


func _on_right_pressed():
	if not int(edit.text) > 256:
		value = int(edit.text) + 1
		edit.text = str(value)
