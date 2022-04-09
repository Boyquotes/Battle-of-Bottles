extends PanelContainer


signal join_server

var server_ip = ""
var active = false


func set_server_name(server_name, ip_adress):
	name = server_name
	$HBoxContainer/VBoxContainer/ServerName.text = server_name
	server_ip = ip_adress


func get_server_ip():
	return server_ip


func set_player_count(count: int):
	$HBoxContainer/VBoxContainer/HBoxContainer2/PlayerCount.show()
	$HBoxContainer/VBoxContainer/HBoxContainer2/Count.show()
	$HBoxContainer/VBoxContainer/HBoxContainer2/Count.text = str(count)


func _on_select_pressed():
	if server_ip != "":
		emit_signal("join_server", server_ip)
