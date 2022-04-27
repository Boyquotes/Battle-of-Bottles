extends Spatial


var frame: int = 0

func _ready():
	pass


func _process(delta):
	if frame > 2:
		queue_free()
	else:
		frame += 1
