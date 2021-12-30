class_name Gun
extends Spatial


const PARTICLE_SCENE = preload("res://assets/particles/HitParticles.tscn")
const BULLET_DECAL_SCENE = preload("res://assets/particles/bullet_decal.tscn")
const DIRT_PARTICLES_SCENE = preload("res://assets/particles/dirt_particles.tscn")

export var damage = 10
export var bullets: int = 1
export var spread_angle_x = 5.0
export var spread_angle_y = 5.0
export var recoil = 0.5
export var distance = 0

export var player_path: NodePath
export var ray_cast_path: NodePath

export var particles_path: NodePath
export var reload_path: NodePath
export var shoot1_path: NodePath
export var shoot2_path: NodePath

onready var particles = get_node(particles_path)
onready var reload = get_node(reload_path)
onready var shoot1 = get_node(shoot1_path)
onready var shoot2 = get_node(shoot2_path)


func _ready():
	pass


func shoot():
	if get_parent().is_spectating or get_parent().reloading:
		return
	var player = get_node(player_path)
	var ray_cast: RayCast = get_node(ray_cast_path)
	ray_cast.cast_to = Vector3(0, 0, distance)
	if Input.is_action_pressed("shoot") or Input.is_action_just_pressed("shoot"):
		if player.ammo > 0:
			# Shoot
			player.is_shooting = true
			player.can_shoot = false
			player.ammo -= 1
			player.current_ammo_label.text = str(get_parent().ammo)
			player.next_recoil = recoil
			rotation_degrees.x += -10
			global_transform.origin.z += -0.10
			particles.emitting = true
			player.shoot_cooldown.start()
			player.get_node("IngameUI").start_cooldown()
			if rand_range(0,2) > 1:
				shoot1.play() # https://freesound.org/people/lensflare8642/sounds/145209/
			else:
				shoot2.play()
			for i in range(bullets):
				#var ray = get_parent().Rotation_Helper/RayCast
				ray_cast.rotation_degrees.x = rand_range(-spread_angle_x, spread_angle_x)
				ray_cast.rotation_degrees.y = rand_range(-spread_angle_y, spread_angle_y)
				ray_cast.force_raycast_update()
				
				if ray_cast.is_colliding() and not ray_cast.get_collider().has_method("bullet_hit"):
					Multiplayer.shoot(ray_cast.get_collision_point())
				else:
					Multiplayer.shoot(Vector3(0,0,0))
				
				if ray_cast.is_colliding():
					var body = ray_cast.get_collider()
					if body == self:
						pass
					elif body.has_method("bullet_hit"):
						body.bullet_hit(damage, ray_cast.global_transform)
						var particle_instance = PARTICLE_SCENE.instance()
						get_parent().get_parent().add_child(particle_instance)
						particle_instance.global_transform.origin = ray_cast.get_collision_point()
						particle_instance.look_at(global_transform.origin, Vector3.UP)
					elif not body.is_in_group("local_player") and not body is RigidBody:
						# Spawn bullet decal
						var bullet_decal = BULLET_DECAL_SCENE.instance()
						get_parent().get_parent().add_child(bullet_decal)
						bullet_decal.scale = Vector3(5, 5, 5)
						bullet_decal.global_transform.origin = ray_cast.get_collision_point()
						if ray_cast.get_collision_normal() == Vector3.DOWN:
							bullet_decal.rotation_degrees.x = -90
						elif ray_cast.get_collision_normal() != Vector3.UP:
							if ray_cast.get_collision_point() + ray_cast.get_collision_normal() != bullet_decal.global_transform.origin:
								bullet_decal.look_at(ray_cast.get_collision_point() + ray_cast.get_collision_normal(), Vector3.UP)
						else:
							bullet_decal.rotation_degrees.x = 90
						# Spawn particles
						var dirt_particles = DIRT_PARTICLES_SCENE.instance()
						get_parent().get_parent().add_child(dirt_particles)
						dirt_particles.scale = Vector3(5, 5, 5)
						dirt_particles.global_transform.origin = ray_cast.get_collision_point()
						#dirt_particles.scale /= ray_cast.get_collider().get_parent().scale
		else:
			if not player.reloading:
				# Reload
				player.reloading = true
				player.reload_cooldown.start()
				reload.play()
	else:
		player.is_shooting = false
