extends Node


export (float) var broadcast_interval = 1.0
var server_info = {"name": "Bottle Server"}

var broadcast = false
var socket_udp
var broadcast_port = 25576

onready var broadcast_timer = $timer


func _ready():
	broadcast_timer.wait_time = broadcast_interval


func enable_broadcast():
	broadcast = true
	broadcast_timer.start()
	socket_udp = PacketPeerUDP.new()
	socket_udp.set_broadcast_enabled(true)
	socket_udp.set_dest_address('255.255.255.255', broadcast_port)


func disable_broadcast():
	broadcast = false
	broadcast_timer.stop()
	if socket_udp != null:
		socket_udp.close()


func broadcast():
	if broadcast:
		var packet_message = to_json(server_info)
		var packet = packet_message.to_ascii()
		socket_udp.put_packet(packet)


func _exit_tree():
	broadcast_timer.stop()
	if socket_udp != null:
		socket_udp.close()
