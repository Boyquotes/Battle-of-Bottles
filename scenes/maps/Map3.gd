extends Spatial


const ZOMBIE_SCENE = preload("res://assets/zombies/Zombie.tscn")

var next_zombie_id = 0
var zombie_queue = []
var wave_active = false
var current_wave = 1


func _ready():
	Multiplayer.map_loaded()
	$WaveCooldown.connect("timeout", self, "_on_WaveCooldown_timeout")
	Multiplayer.connect("new_zombie", self, "_on_Multiplayer_new_zombie")
	Multiplayer.connect("other_loaded", self, "_other_loaded")
	if Multiplayer.is_zombie_master:
		$WaveCooldown.start()


func _process(delta):
	if $Navigation/Zombies.get_child_count() == 0:
		if not wave_active:
			wave_active = true
			$WaveCooldown.start()
			print("wave starts soon")
		elif $WaveCooldown.is_stopped():
			wave_active = false

	try_spawn_zombie()


func new_wave(zombie_count):
	var spawn_points =$ZombieSpawnPoints.get_children()
	
	var player_ids = []
	var info = Multiplayer.player_info
	for i in info.keys():
		if i == 1 and info[1]["info"]["name"] == "_server":
			continue
		else:
			player_ids.append(i)
	
	if get_tree().get_network_unique_id() != null:
		player_ids.append(get_tree().get_network_unique_id())
	else:
		player_ids.append(-1)
	
	var spawn_point_sum = Vector3(0, 0, 0)
	for i in player_ids:
		if i == get_tree().get_network_unique_id() or i == -1:
			spawn_point_sum += $Player.global_transform.origin
		else:
			spawn_point_sum += Multiplayer.player_info[i]["instance"].transform.origin
	var avrg_pos = spawn_point_sum / player_ids.size()
	
	var zombie_spawns = []
	for n in range(3):
		var distances = []
		for i in spawn_points:
			distances.append(i.global_transform.origin.distance_to(avrg_pos))
		var nearest_spawn = spawn_points[distances.find(distances.min())]
		zombie_spawns.append(nearest_spawn.global_transform.origin)
				
		spawn_points.erase(nearest_spawn)

	for i in range(zombie_count):
		var zombie = ZOMBIE_SCENE.instance()
		zombie.name = str(next_zombie_id)
		zombie.target_id = player_ids[randi() % player_ids.size()]
		zombie.id = next_zombie_id
		zombie.transform.origin = zombie_spawns[randi() % zombie_spawns.size()]
		zombie_queue.append(zombie)
		next_zombie_id += 1


func _on_WaveCooldown_timeout():
	print("wave " + str(current_wave) +  " starts: " + str(pow(current_wave, 2)))
	wave_active = true
	new_wave(current_wave * 2 + 4)
	current_wave += 1


func try_spawn_zombie():
	if zombie_queue.size() > 0:
		var zombie = zombie_queue.back()
		Multiplayer.new_zombie(zombie.name, zombie.target_id, zombie.id, zombie.transform.origin)
		$Navigation/Zombies.add_child(zombie)
		zombie_queue.pop_back()


func _on_Multiplayer_new_zombie(name, target_id, id, origin):
	print("new zombie")
	var zombie = ZOMBIE_SCENE.instance()
	zombie.name = name
	zombie.target_id = target_id
	zombie.id = id
	zombie.transform.origin = origin
	$Navigation/Zombies.add_child(zombie)


func _other_loaded(id):
	if Multiplayer.is_zombie_master:
		for i in $Navigation/Zombies.get_children():
			Multiplayer.new_zombie_with_id(id, i.name, i.target_id, i.id, i.transform.origin)

