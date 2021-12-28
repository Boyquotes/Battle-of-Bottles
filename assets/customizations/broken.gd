extends Spatial


const BASE_BULLET_BOOST = 10


func _ready():
	$Free.connect("timeout", self, "kill")


func setup(pos: Vector3, rot: Vector3, bullet_global_transform):
	$smash.pitch_scale = rand_range(0.9, 1.05)
	global_transform.origin = pos
	rotation = rot
	$Free.start()
	for i in get_children():
		if i is RigidBody:
			i.apply_impulse((i.global_transform.origin - bullet_global_transform.origin).normalized(), bullet_global_transform.basis.z.normalized() * BASE_BULLET_BOOST)


func kill():
	queue_free()
