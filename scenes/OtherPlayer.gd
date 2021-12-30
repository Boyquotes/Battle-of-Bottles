extends Spatial


const DIRT_PARTICLES_SCENE = preload("res://assets/particles/dirt_particles.tscn")

var id
var current_weapon = "machinegun"
var customizations = {
	"hats": {
		"": ["none", null],
		"pizza": ["Italian Hat", preload("res://assets/customizations/Pizza.tscn")],
		"german": ["German Hat", preload("res://assets/customizations/German.tscn")],
		"banana": ["Banana Hat", preload("res://assets/customizations/Banana.tscn")],
		"hat": ["Bowler Hat", preload("res://assets/customizations/Hat.tscn")],
		"holiday_hat": ["Holiday Hat", preload("res://assets/customizations/Holiday.tscn")],
		"sunglasses": ["Sunglasses", preload("res://assets/customizations/Sunglasses.tscn")]
	},
	"bottles": {
		"default_bottle": ["Default", preload("res://assets/customizations/DefaultBottle.tscn"), preload("res://assets/customizations/DefaultBottle_broken.tscn")],
		"ketchup_bottle": ["Ketchup", preload("res://assets/customizations/KetchupBottle.tscn"), preload("res://assets/customizations/KetchupBottle_broken.tscn")],
		"superbottle": ["Superbottle", preload("res://assets/customizations/SuperBottle.tscn"), preload("res://assets/customizations/SuperBottle_broken.tscn")]
	}
}

onready var guns = {
	# "unarmed": [null, 0, 0, false],
	"machinegun": $machinegun,
	"shotgun": $shotgun,
	"sniper": $sniper,
}


func _ready():
	guns[current_weapon].show()


func customize(player_customizations: Dictionary):
	for i in player_customizations.keys():
		if customizations.has(i):
			if customizations[i].has(player_customizations[i]):
				if customizations[i][player_customizations[i]][1] != null:
					$Customizations.add_child(customizations[i][player_customizations[i]][1].instance())


func customization_reset():
	for i in $Customizations.get_children():
		i.queue_free()


func bullet_hit(damage, bullet_global_trans):
	Multiplayer.hit_other_player(id, damage, bullet_global_trans)


func shoot(hit_pos: Vector3):
	guns[current_weapon].get_node("Particles").emitting = true
	guns[current_weapon].get_node("3d_shoot").play()
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
