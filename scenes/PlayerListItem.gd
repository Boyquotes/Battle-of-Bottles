extends Control


var player_name
var id
var is_kickable = false

var kills
var deaths

onready var name_label = $HBoxContainer/VBoxContainer/PlayerName
onready var k_label = $"HBoxContainer/VBoxContainer/HBoxContainer2/Kills"
onready var d_label = $"HBoxContainer/VBoxContainer/HBoxContainer2/Deaths"
onready var kd_label = $"HBoxContainer/VBoxContainer/HBoxContainer2/KD"


func _ready():
	name_label.text = player_name
	k_label.text = str(kills)
	d_label.text = str(deaths)
	if deaths != 0:
		kd_label.text = str((kills as float)/(deaths as float)).pad_decimals(2)
	else:
		kd_label.text = "NaN"
	if is_kickable:
		$HBoxContainer/VBoxContainer/HBoxContainer.show()

func _on_Button_pressed():
	get_tree().network_peer.disconnect_peer(id)
	queue_free()
