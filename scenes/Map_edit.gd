extends Panel


var current_index = 0
var current_map

onready var maps = Multiplayer.maps
onready var label = $HBoxContainer/Label


func _ready():
	label.text = maps[maps.keys()[current_index]][0]
	current_map = maps.keys()[current_index]


func _on_left_pressed():
	current_index -= 1
	if current_index < 0:
		current_index = maps.size() - 1
	label.text = maps[maps.keys()[current_index]][0]
	current_map = maps.keys()[current_index]


func _on_right_pressed():
	current_index += 1
	if current_index > maps.size() - 1:
		current_index = 0
	label.text = maps[maps.keys()[current_index]][0]
	current_map = maps.keys()[current_index]
