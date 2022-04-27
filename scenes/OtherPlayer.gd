extends Spatial


const DIRT_PARTICLES_SCENE = preload("res://assets/particles/dirt_particles.tscn")

var id
var current_weapon = "machinegun"

onready var guns = {
	# "unarmed": [null, 0, 0, false],
	"machinegun": $machinegun,
	"shotgun": $shotgun,
	"sniper": $sniper,
}


func _ready():
	guns[current_weapon].show()


func customize(player_customizations: Dictionary):
	var customizations = Global.customizations
	for i in player_customizations.keys():
		if customizations.has(i):
			if customizations[i].has(player_customizations[i]):
				if i == "bottles":
					if customizations[i][player_customizations[i]][2] != null:
						$Customizations.add_child(customizations[i][player_customizations[i]][2].instance())
				else:
					if customizations[i][player_customizations[i]][1] != null:
						$Customizations.add_child(customizations[i][player_customizations[i]][1].instance())


func customization_reset():
	for i in $Customizations.get_children():
		i.queue_free()


func bullet_hit(damage, bullet_global_trans):
	Multiplayer.hit_other_player(id, damage, bullet_global_trans)


func shoot(hit_pos: Vector3):
	var particles: Particles = guns[current_weapon].get_node("Particles")
	particles.emitting = true
	guns[current_weapon].get_node("3d_shoot").play()
	guns[current_weapon].show_trail(particles.global_transform.origin, hit_pos)
	if hit_pos != Vector3(0,0,0) and get_parent() != null:
		var dirt_particles = DIRT_PARTICLES_SCENE.instance()
		get_parent().add_child(dirt_particles)
		dirt_particles.global_transform.origin = hit_pos
		dirt_particles.scale = Vector3(5,5,5)


func change_weapon(weapon):
	guns[current_weapon].hide()
	if guns.has(weapon):
		guns[weapon].show()
		current_weapon = weapon
