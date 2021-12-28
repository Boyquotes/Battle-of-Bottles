extends Spatial


func _ready():
	$Free.connect("timeout", self, "kill")
	$Free.start()
	for i in get_children():
		if i is Particles:
			i.emitting = true


func kill():
	queue_free()
