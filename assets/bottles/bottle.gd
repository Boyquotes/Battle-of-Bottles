extends RigidBody


const BASE_BULLET_BOOST = 0.5

export var id: int


func _ready():
	Multiplayer.connect("bottle_hit", self, "network_bullet_hit")
	Multiplayer.connect("bottle_set_pos", self, "set_pos")
	$clonk.stream.loop = false


func bullet_hit(damage, bullet_global_trans):
	var direction_vect = bullet_global_trans.basis.z.normalized() * BASE_BULLET_BOOST
	$clonk.pitch_scale = rand_range(0.9, 1.05) # Random bottle pitch
	$clonk.play()
	apply_impulse((bullet_global_trans.origin - global_transform.origin).normalized(), direction_vect * damage)
	Multiplayer.bottle_hit(id, damage, bullet_global_trans)


func network_bullet_hit(other_id, damage, bullet_global_trans):
	if other_id == id:
		var direction_vect = bullet_global_trans.basis.z.normalized() * BASE_BULLET_BOOST
		$clonk.pitch_scale = rand_range(0.9, 1.05) # Random bottle pitch
		$clonk.play()
		apply_impulse((bullet_global_trans.origin - global_transform.origin).normalized(), direction_vect * damage)


func set_pos(other_id, position, rot):
	if other_id == id:
		translation = position
		rotation = rot
