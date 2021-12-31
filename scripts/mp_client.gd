extends Node

signal hit
signal loading_map
signal other_loaded
signal zombie_hit
signal zombie_die
signal new_zombie
signal zombie_sync
signal bottle_set_pos
signal bottle_hit
signal player_died
signal cam_to_map

const SERVER_PORT = 25575
const PROTOCOL_VERSION = "1.1-dev"

var other_player_scene
var connected = false
var dead = false

var is_bottle_master = false
var is_zombie_master = false

var is_map_loaded = false
var is_server = false
var current_map

var spectator_camera

var new_player_queue = []

var my_info = {}
var player_info = {}

var maps = {
	"default": ["Default Map", "res://scenes/maps/Map.tscn"],
	"city": ["City Map", "res://scenes/maps/Map2.tscn"],
	"zombie_map": ["Zombie Map", "res://scenes/maps/Map3.tscn"],
	}

var kills = 0
var deaths = 0

onready var other_player_script = preload("res://scenes/OtherPlayer.gd").new()

func _ready():

	other_player_scene = preload("res://scenes/OtherPlayer.tscn")

	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func activate_multiplayer(ip: String):
	print("client")
	my_info = { "name": Global.settings["username"], "customizations": Global.user_customization, "mods": Mods.get_active().keys()}
	var peer = NetworkedMultiplayerENet.new()
	print(peer.create_client(ip, SERVER_PORT))
	get_tree().network_peer = peer
	is_server = false


func host_game(max_players, map):
	print("server")
	my_info = { "name": Global.settings["username"], "customizations": Global.user_customization, "mods": Mods.get_active().keys()}
	var peer = NetworkedMultiplayerENet.new()
	print(peer.create_server(SERVER_PORT, max_players))
	get_tree().network_peer = peer
	is_bottle_master = true
	is_zombie_master = true
	if maps.has(map):
		#get_tree().change_scene_to(load(maps[map][1]))
		BackgroundLoader.load_scene(maps[map][1])
	current_map = map
	connected = true
	is_server = true


func stop_multiplayer():
	connected = false
	is_map_loaded = false
	kills = 0
	deaths = 0
	get_tree().network_peer = null
	player_info = {}


func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
	rpc_id(id, "register_player", my_info, [kills, deaths])
	if is_server:
		rpc_id(id, "set_map", current_map)
		rpc_id(id, "protocol_version_check", PROTOCOL_VERSION)
	print(str(id) + " connected")

remote func protocol_version_check(version):
	if version != PROTOCOL_VERSION:
		stop_multiplayer()
		get_tree().change_scene("res://scenes/Outdated.tscn")

remote func mods_check(client_mods):
	if Mods.get_active().keys().hash() != client_mods.hash():
		Global.required_mods = client_mods
		stop_multiplayer()
		get_tree().change_scene("res://scenes/InvalidMods.tscn")

func _player_disconnected(id):
	if is_map_loaded:
		if player_info.has(id):
			player_info[id]["instance"].queue_free()
			player_info.erase(id) # Erase player from info.


func _connected_ok():
	print("connected ok")
	connected = true


func _server_disconnected():
	stop_multiplayer()
	get_tree().change_scene("res://scenes/ServerDisconnected.tscn")


func _connected_fail():
	print("connection failed")
	stop_multiplayer()
	get_tree().change_scene("res://scenes/ConnectionFailed.tscn")


remote func register_player(info, stats):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	
	var player_instance = other_player_scene.instance()
	player_instance.name = str(id)
	player_instance.set_network_master(id)
	player_instance.id = id
	if info.has("customizations"):
		player_instance.customize(info["customizations"])
	player_info[id] = {
		"info": info,
		"instance": player_instance,
		"stats": stats
	}
	new_player_queue.append(player_instance)


remote func set_bottle_position(id, position, rotation):
	if is_map_loaded:
		emit_signal("bottle_set_pos", id, position, rotation)


remote func update_position(position: Vector3, rot: Vector3):
	if is_map_loaded:
		var id = get_tree().get_rpc_sender_id()
		if player_info.has(id):
			var player: KinematicBody = player_info[id]["instance"]
			player.transform.origin = position
			player.rotation = rot


remote func hit(damage, bullet_global_trans):
	if is_map_loaded:
		print("hit: " + str(damage) + ", " + str(bullet_global_trans))
		emit_signal("hit", damage, bullet_global_trans, get_tree().get_rpc_sender_id())


remote func other_shoot(hit_pos: Vector3):
	if is_map_loaded:
		var id = get_tree().get_rpc_sender_id()
		player_info[id]["instance"].shoot(hit_pos)


remote func other_bottle_hit(id, damage, bullet_global_trans):
	if is_map_loaded:
		emit_signal("bottle_hit", id, damage, bullet_global_trans)


func shoot(hit_pos: Vector3):
	if connected:
		rpc("other_shoot", hit_pos)


func die(pos: Vector3, rot: Vector3, bullet_global_transform: Transform, id):
	if not dead:
		dead = true
		if connected:
			if id >= 1:
				player_info[id]["stats"][0] += 1
			deaths += 1
			rpc("player_dead", pos, rot, bullet_global_transform, id)
			if player_info.has(id):
				var other_player = player_info[id]["instance"]
				var camera = Camera.new()
				other_player.hide()
				other_player.add_child(camera)
				camera.name = "spectator"
				camera.rotation_degrees.y = 180
				camera.global_transform.origin.y += 1
				camera.far = 1000
				camera.make_current()
				spectator_camera = camera
			else:
				emit_signal("cam_to_map")
		else:
			emit_signal("cam_to_map")


func suicide(pos: Vector3, rot: Vector3, bullet_global_transform: Transform, id):
	dead = true
	if connected:
		rpc("player_dead", pos, rot, bullet_global_transform, id)


remote func player_dead(pos: Vector3, rot: Vector3, bullet_global_transform: Transform, killer_id: int):
	var id = get_tree().get_rpc_sender_id()
	if killer_id != get_tree().get_network_unique_id():
		if killer_id >= 1:
			player_info[killer_id]["stats"][0] += 1
	else:
		kills += 1
	player_info[id]["stats"][1] += 1
	emit_signal("player_died", id, pos, rot, bullet_global_transform, killer_id)


func player_respawn(id):
	if connected:
		rpc("respawn")
	dead = false
	if id == null:
		var cam = spectator_camera
		if cam != null:
			cam.queue_free()
	if player_info.has(id):
		var camera = spectator_camera
		player_info[id]["instance"].show()
		if camera != null:
			camera.queue_free()
	else:
		var cam = spectator_camera
		if cam != null:
			cam.queue_free()


func change_weapon(weapon):
	if connected:
		rpc("other_change_weapon", weapon)


func map_loaded():
	is_map_loaded = true
	if connected:
		rpc("other_map_loaded")


func send_bottle_pos(target_id, bottle_id, position, rot):
	if connected:
		rpc_id(target_id, "set_bottle_position", bottle_id, position, rot)


remote func other_map_loaded():
	var id = get_tree().get_rpc_sender_id()
	emit_signal("other_loaded", id)


remote func other_change_weapon(weapon):
	if is_map_loaded:
		var id = get_tree().get_rpc_sender_id()
		player_info[id]["instance"].change_weapon(weapon)


remote func respawn():
	if is_map_loaded:
		player_info[get_tree().get_rpc_sender_id()]["instance"].show()


remote func set_bottle_master(arg):
	print("bottle master")
	is_bottle_master = arg


remote func set_zombie_master(arg):
	print("zombie master")
	is_zombie_master = arg


func bottle_hit(name, damage, bullet_global_trans):
	if connected:
		rpc("other_bottle_hit", name, damage, bullet_global_trans)


func hit_other_player(id, damage, bullet_global_trans):
	if connected:
		rpc_id(id, "hit", damage, bullet_global_trans)


remote func set_map(map):
	print("set map: " + map)
	if get_tree().get_rpc_sender_id() == 1:
		if maps.has(map):
			emit_signal("loading_map", map)
			#get_tree().change_scene_to(load(maps[map][1]))


func send_position(pos, rot):
	if connected:
		rpc_unreliable("update_position", pos, rot)


func get_username_from_id(id):
	if player_info.has(id):
		return player_info[id]["info"]["name"]
	elif id == -1:
		return "GOT YA BRAIN"
	return "yourself"


func new_zombie(name, target_id, id, origin):
	if connected:
		rpc("other_new_zombie", name, target_id, id, origin)


func new_zombie_with_id(player_id, name, target_id, id, origin):
	if connected:
		rpc_id(player_id, "other_new_zombie", name, target_id, id, origin)


func zombie_hit(id, damage, bullet_global_trans):
	if connected:
		rpc("other_zombie_hit", id, damage, bullet_global_trans)


func zombie_sync(id, origin):
	if connected:
		rpc("other_zombie_sync", id, origin)


func zombie_die(id, bullet_global_transform):
	if connected:
		rpc("other_zombie_die", id, bullet_global_transform)


remote func other_zombie_hit(id, damage, bullet_global_trans):
	emit_signal("zombie_hit", id, damage, bullet_global_trans)


remote func other_zombie_die(id, bullet_global_transform):
	emit_signal("zombie_die", id, bullet_global_transform)


remote func other_new_zombie(name, target_id, id, origin):
	print("got rpc call")
	emit_signal("new_zombie", name, target_id, id, origin)


remote func other_zombie_sync(id, origin):
	emit_signal("zombie_sync", id, origin)
