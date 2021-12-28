extends Spatial


func _ready():
	Multiplayer.connect("other_loaded", self, "_other_loaded")


func _other_loaded(id):
	if Multiplayer.is_bottle_master:
		for i in $Bottles.get_children():
			Multiplayer.send_bottle_pos(id, i.id, i.transform.origin, i.rotation)
