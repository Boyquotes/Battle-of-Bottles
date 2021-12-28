extends Particles


func _ready():
	$Free.connect("timeout", self, "kill")
	$Free.start()
	$Clonk.stream.loop = false
	emitting = true
	$Clonk.play()


func kill():
	queue_free()
