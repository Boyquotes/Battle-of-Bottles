extends KinematicBody


const SPEED = 10
const DAMAGE = 25

var id
var path = []
var current_path_node = 0
var health = 50
var momentum = Vector3(0,0,0)

var customizations = {
	"hats": {
		"": ["none", null],
		"pizza": ["Italian Hat", load("res://assets/customizations/Pizza.tscn")],
		"german": ["German Hat", load("res://assets/customizations/German.tscn")],
		"banana": ["Banana Hat", load("res://assets/customizations/Banana.tscn")],
		"hat": ["Bowler Hat", load("res://assets/customizations/Hat.tscn")]
	},
	"bottles": {
		"zombie_bottle": ["Zombie Bottle", load("res://assets/customizations/ZombieBottle.tscn"), load("res://assets/customizations/ZombieBottle_broken.tscn")],
	},
}

var own_customization = {}

var target : Spatial
var target_id : int

onready var nav = get_parent().get_parent()
onready var map = get_parent().get_parent().get_parent()


func _ready():
	Multiplayer.connect("zombie_hit", self, "_on_Multiplayer_zombie_hit")
	Multiplayer.connect("zombie_die", self, "_on_Multiplayer_zombie_die")
	Multiplayer.connect("zombie_sync", self, "_on_Multiplayer_zombie_sync")
	$HitTimer.connect("timeout", self, "hit_player")
	$Timer.connect("timeout", self, "new_path")
	if Multiplayer.is_zombie_master:
		$Timer.start()
	if target == null:
		if target_id == get_tree().get_network_unique_id() or target_id == -1:
			target = map.get_node("Player")
		else:
			if Multiplayer.player_info.has(target_id):
				target = Multiplayer.player_info[target_id]["instance"]
	for i in customizations.keys():
		own_customization[i] = customizations[i].keys()[randi() % customizations[i].size() - 1]
		customize(own_customization)


func _physics_process(delta):
	if current_path_node < path.size():
		var dir = path[current_path_node] - global_transform.origin
		if dir.length() < 1:
			current_path_node += 1
		else:
			momentum = momentum + dir.normalized() * SPEED * 0.1
	#if path.size() > current_path_node + 1 and transform.origin.distance_to(target.transform.origin) > 5:
	#	transform = transform.looking_at(Vector3(path[current_path_node + 1].x, global_transform.origin.y,path[current_path_node + 1].z), Vector3.UP)
	if target != null:
		transform = transform.looking_at(target.transform.origin, Vector3.UP)
	rotation_degrees.y += 180
	rotation_degrees.x = 0
	rotation_degrees.z = 0
	move_and_slide(momentum, Vector3.UP)
	momentum *= 0.9


func customize(player_customizations: Dictionary):
	for i in player_customizations.keys():
		if customizations.has(i):
			if customizations[i].has(player_customizations[i]):
				if customizations[i][player_customizations[i]][1] != null:
					$Customizations.add_child(customizations[i][player_customizations[i]][1].instance())


func pathfind_to(target: Vector3):
	path = nav.get_simple_path(global_transform.origin, target)
	current_path_node = 0


func bullet_hit(damage, bullet_global_trans):
	if Multiplayer.is_zombie_master:
		hit(damage, bullet_global_trans)
	else:
		Multiplayer.zombie_hit(id, damage, bullet_global_trans)


func hit(damage, bullet_global_trans):
	if health <= 0:
		return
	else:
		health -= damage
		if health <= 0:
			die(bullet_global_trans)


func die(bullet_global_transform):
	#print("die")
	if Multiplayer.is_zombie_master:
		Multiplayer.zombie_die(id, bullet_global_transform)
	var broken_player_inst = customizations["bottles"][own_customization["bottles"]][2].instance()
	get_node("/root/Map/").add_child(broken_player_inst)
	broken_player_inst.setup(global_transform.origin, rotation, bullet_global_transform)
	#map.add_child(broken_player_inst)
	queue_free()


func hit_player():
	var area = $Area
	var bodies = area.get_overlapping_bodies()

	for body in bodies:
		if body.has_method("self_hit"):
			body.self_hit(DAMAGE, area.global_transform, -1)


func _on_Multiplayer_zombie_hit(other_id, damage, bullet_global_trans):
	if Multiplayer.is_zombie_master:
		if other_id == id:
			hit(damage, bullet_global_trans)


func _on_Multiplayer_zombie_die(other_id, bullet_global_trans):
	if other_id == id:
		die(bullet_global_trans)


func _on_Multiplayer_zombie_sync(other_id, origin):
	if other_id == id:
		global_transform.origin = origin
		new_path()


func new_path():
	if Multiplayer.is_zombie_master:
		Multiplayer.zombie_sync(id, global_transform.origin)
	if target != null:
		pathfind_to(target.global_transform.origin)
