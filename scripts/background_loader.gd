extends Node


var thread = null


func _thread_load(path):
	var ril = ResourceLoader.load_interactive(path)
	assert(ril)
	var total = ril.get_stage_count()
	var res = null
	
	while true:
		var err = ril.poll()
		if err == ERR_FILE_EOF:
			res = ril.get_resource()
			break
		elif err != OK:
			print("There was an error loading")
			break
	
	call_deferred("_thread_done", res)


func _thread_done(resource):
	assert(resource)
	
	thread.wait_to_finish()
	
	if Multiplayer.connected:
		var new_scene = resource.instance()
		get_tree().current_scene.free()
		get_tree().current_scene = null
		get_tree().root.add_child(new_scene)
		get_tree().current_scene = new_scene


func load_scene(path):
	thread = Thread.new()
	thread.start(self, "_thread_load", path)
