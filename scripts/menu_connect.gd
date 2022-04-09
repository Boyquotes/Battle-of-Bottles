extends MarginContainer


var socket_udp = PacketPeerUDP.new()
var listen_port = 25576
var known_servers = []
var server_list_item_scene = preload("res://scenes/ServerListItem.tscn")

onready var server_list = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/ScrollContainer/server_list
onready var connect_loading = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/loading


func _ready():
	if socket_udp.listen(listen_port) != OK:
		print("Error listening on port " + str(listen_port))


func _process(delta):
	if socket_udp.get_available_packet_count() > 0:
		var server_ip = socket_udp.get_packet_ip()
		var server_port = socket_udp.get_packet_port()
		var array_bytes = socket_udp.get_packet()
		
		if server_ip != '' and server_port > 0 and not server_ip in known_servers:
			print("info received")
			var server_list_item = server_list_item_scene.instance()
			var info: Dictionary = parse_json(array_bytes.get_string_from_ascii())
			if info.has("name"):
				server_list_item.set_server_name(info["name"], server_ip)
			else:
				server_list_item.set_server_name("Unknown Server", server_ip)
			if info.has("player_count"):
				server_list_item.set_player_count(int(info["player_count"]))
			server_list_item.connect("join_server", self, "join_server")
			server_list.add_child(server_list_item)
			connect_loading.hide()
			known_servers.append(server_ip)
			socket_udp.close()


func stop_listening():
	socket_udp.close()


func _exit_tree():
	socket_udp.close()


func reset():
	known_servers = []
	socket_udp.listen(listen_port)


func join_server(ip_address):
	Global.IP = ip_address
	get_tree().change_scene("res://scenes/LoadMap.tscn")
