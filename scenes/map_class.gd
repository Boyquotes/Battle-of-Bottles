class_name Map
extends Spatial


export var other_players_path: NodePath
export var player_path: NodePath

var other_players
var player


func _ready():
	other_players = get_node(other_players_path)
	player = get_node(player_path)
	refresh_queue()
	Multiplayer.connect("player_died", self, "_player_died")
	player.connect("died", self, "self_died")
	Multiplayer.connect("cam_to_map", self, "_cam_to_map")
	Multiplayer.map_loaded()


func _process(delta):
	refresh_queue()
	if not Multiplayer.dead:
		Multiplayer.send_position(player.transform.origin, player.rotation)
	else:
		Multiplayer.send_position(Vector3(0,-10,0), Vector3(0,0,0))


func _player_died(id, pos, rot, bullet_global_transform):
	var player_info = Multiplayer.player_info
	player_info[id]["instance"].hide() # Hide player until they respawn
	if Global.customizations["bottles"].has(player_info[id]["info"]["customizations"]["bottles"]):
		var broken_player_inst = Global.customizations["bottles"][player_info[id]["info"]["customizations"]["bottles"]][3].instance()
		add_child(broken_player_inst)
		broken_player_inst.setup(pos, rot, bullet_global_transform)


func self_died(pos: Vector3, rot: Vector3, bullet_global_transform: Transform):
	var broken_player_inst = Global.customizations["bottles"][Global.user_customization["bottles"]][3].instance()
	add_child(broken_player_inst)
	broken_player_inst.setup(pos, rot, bullet_global_transform)


func _cam_to_map():
	var camera = Camera.new()
	get_node("/root/Map/").add_child(camera)
	camera.name = "spectator"
	camera.global_transform.origin = Vector3(0,2,0)
	camera.rotation_degrees.y = 90
	camera.far = 1000
	camera.make_current()
	Multiplayer.spectator_camera = camera


func refresh_queue():
	if Multiplayer.connected:
		for i in Multiplayer.new_player_queue:
			other_players.add_child(i)
			Multiplayer.player_added(i.id)
			Multiplayer.new_player_queue.erase(i)
