extends KinematicBody


signal health_changed
signal died
signal hit

const GRAVITY = -24.8
const MAX_SPEED = 15
const JUMP_POWER = 10
const ACCEL = 2.5
const DEACCEL= 16
const AIR_ACCEL = 1
const AIR_DEACCEL = 2.5
const DAMAGE = 10
const GUN_SPEED = 5.0
const GUN_SHAKE_AMOUNT = 1.0
const GUN_SHAKE_SPEED = 1.0
const GUN_SHOOT_ANIMATION_SPEED = 1.0
const MAX_HEALTH = 100
const DEATH_SCREEN_LENGTH = 3
const NATURAL_REGENERATION_SPEED = 2
const RECOIL_STRENGTH = 10.0
const MAX_SLOPE_ANGLE = 40
const DEFAULT_FOV = 70
const ZOOM_FOV = 30
const SCOPE_FOV = 5
const DEFAULT_MOUSE_SENSITIVITY = 0.05
const SCOPE_MOUSE_SENSITIVITE = 0.00357

export(float, 0.0, 1.0) var fov_acceleration = 0.1
export var fall_damage_factor = 2.5

var vel = Vector3()
var dir = Vector3()
var is_walking = false
var is_spectating = false
var can_shoot = true
var reloading = false
var default_ammo
var ammo = default_ammo
var reload_time
var next_recoil = 0 # This variable can be changed by weapons to apply recoil.
var current_weapon
var current_weapon_index = 0
var weapon_index_changed = false
var health
var zooming = false
var is_scoping = false
var target_fov = DEFAULT_FOV
var mouse_sensitivity_multiplier = 1
var ZOOM_MOUSE_SENSITIVITY = 0.02
var MOUSE_SENSITIVITY = DEFAULT_MOUSE_SENSITIVITY
var target_mouse_sensitivity = DEFAULT_MOUSE_SENSITIVITY
var is_shooting = true
var fall_damage = 0

onready var camera = $Rotation_Helper/Camera
onready var rotation_helper = $Rotation_Helper
onready var IngameUI = $IngameUI
onready var max_ammo_label = $IngameUI/ammo/max
onready var current_ammo_label = $IngameUI/ammo/current
onready var shoot_cooldown = $shoot_cooldown
onready var reload_cooldown = $reload_cooldown
onready var map = get_parent()


onready var guns = {
	#"unarmed": [gun node, current ammo, max ammo, uses scope, is mg, shoot cooldown, reload time],
	"machinegun": [$machinegun, 30, 30, false, true, 0.1, 0.5],
	"shotgun": [$shotgun, 6, 6, false, false, 1.35, 3.0],
	"sniper": [$sniper, 10, 10, true, false, 2.4, 3.0],
}


func _ready():
	if get_parent().is_in_group("zombie_scene"):
		IngameUI.toggle_minimap(true)
	
	current_weapon = guns.keys()[current_weapon_index]
	guns[current_weapon][0].show()
	default_ammo = guns[current_weapon][1]
	ammo = guns[current_weapon][2]
	shoot_cooldown.wait_time = guns[current_weapon][5]
	reload_time = guns[current_weapon][6]
	reload_cooldown.wait_time = reload_time
	max_ammo_label.text = str(default_ammo)
	current_ammo_label.text = str(ammo)
	
	if Global.settings.has("mouse_sensitivity"):
		mouse_sensitivity_multiplier = Global.settings["mouse_sensitivity"]
	
	randomize()
	camera.fov = DEFAULT_FOV
	
	shoot_cooldown.connect("timeout", self, "shoot_cooldown")
	reload_cooldown.connect("timeout", self, "reload_cooldown")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	Multiplayer.connect("hit", self, "_on_Multiplayer_hit")
	
	health = MAX_HEALTH
	spawn()


var t = 0
func _process(delta):
	if global_transform.origin.y < -10:
		if Multiplayer.connected:
			die(transform, 0)
		else:
			die(transform, 0)
	$GunRotationHelper.look_at($Rotation_Helper/machinegun_shoot_target.global_transform.origin, Vector3.UP)
	var gun_node = guns[current_weapon][0]
	if reloading:
		gun_node.rotate_x(deg2rad(delta * -0.5 * 360))
	else:
		gun_node.rotation = gun_node.rotation.linear_interpolate($GunRotationHelper.rotation, delta * GUN_SPEED)
	if zooming:
		gun_node.global_transform.origin = gun_node.global_transform.origin.linear_interpolate($Rotation_Helper/machinegun_target_zoom.global_transform.origin, delta * GUN_SPEED)
	else:
		gun_node.global_transform.origin = gun_node.global_transform.origin.linear_interpolate($Rotation_Helper/machinegun_target.global_transform.origin, delta * GUN_SPEED)
	if is_walking:
		t += delta
		gun_node.global_transform.origin.y += sin(t * 10 * GUN_SHAKE_SPEED) * 0.01 * GUN_SHAKE_AMOUNT
	else:
		t = 0
	
	camera.fov = lerp(camera.fov, self.target_fov, self.fov_acceleration)
	MOUSE_SENSITIVITY = lerp(MOUSE_SENSITIVITY, target_mouse_sensitivity, fov_acceleration)
	
	health = clamp(health + delta * NATURAL_REGENERATION_SPEED, 0, MAX_HEALTH)
	emit_signal("health_changed", health)
	
	IngameUI.update_minimap(Vector2((global_transform.origin.x + 255)/345, (global_transform.origin.z - 130)/335), rotation_degrees.y)


func _on_Multiplayer_hit(damage, bullet_global_trans, id):
	if health <= 0:
		return
	else:
		health -= damage
		if health <= 0:
			die(bullet_global_trans, id)
			print(id)
		emit_signal("health_changed", health)
		if health > 0:
			emit_signal("hit", bullet_global_trans)


func self_hit(damage, bullet_global_trans, id):
	if health <= 0:
		return
	else:
		health -= damage
		if health <= 0:
			die(bullet_global_trans, id)
		emit_signal("health_changed", health)
		if health > 0:
			emit_signal("hit", bullet_global_trans)


func _physics_process(delta):
	process_input(delta)
	process_changing_weapons(delta)
	process_movement(delta)
	if Input.is_action_just_pressed("shoot") and can_shoot and not IngameUI.paused:
		guns[current_weapon][0].shoot()


func process_input(delta):
	dir = Vector3()
	var cam_xform = camera.get_global_transform()
	
	var input_movement_vector = Vector2()
	
	is_walking = false
	if not IngameUI.paused:
		if Input.is_action_pressed("movement_forward") or Input.is_action_pressed("movement_backward"):
			input_movement_vector.y = Input.get_action_strength("movement_forward") - Input.get_action_strength("movement_backward")
			is_walking = true
		if Input.is_action_pressed("movement_right") or Input.is_action_pressed("movement_left"):
			input_movement_vector.x = Input.get_action_strength("movement_right") - Input.get_action_strength("movement_left")
			is_walking = true
	
	input_movement_vector = input_movement_vector.normalized()
	
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	
	if is_on_floor() and not IngameUI.paused:
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_POWER
	
	if next_recoil != 0:
		vel += camera.global_transform.basis.z * RECOIL_STRENGTH * next_recoil
		next_recoil = 0
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			IngameUI.show_pause_menu()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			IngameUI.hide_pause_menu()
	
	if Input.is_action_pressed("zoom") and not is_spectating and not IngameUI.paused:
		zooming = true
		if guns[current_weapon][3]:
			target_fov = SCOPE_FOV
			target_mouse_sensitivity = SCOPE_MOUSE_SENSITIVITE
			if not is_scoping:
				scope()
		else:
			target_fov = ZOOM_FOV
			target_mouse_sensitivity = ZOOM_MOUSE_SENSITIVITY
	else:
		zooming = false
		target_fov = DEFAULT_FOV
		target_mouse_sensitivity = DEFAULT_MOUSE_SENSITIVITY
	
	if Input.is_action_just_released("zoom") and is_scoping and not IngameUI.paused:
		unscope()
	
	if Input.is_action_just_pressed("weapon_up"):
		current_weapon_index += 1
		if current_weapon_index > guns.size() - 1:
			current_weapon_index = 0
		weapon_index_changed = true
	elif Input.is_action_just_pressed("weapon_down"):
		current_weapon_index -= 1
		if current_weapon_index < 0:
			current_weapon_index = guns.size() - 1
		weapon_index_changed = true


func process_changing_weapons(delta):
	if weapon_index_changed:
		if guns[current_weapon][3] and is_scoping:
			unscope()
		guns[current_weapon][0].hide()
		guns[current_weapon][2] = ammo
		var new_weapon = guns.keys()[current_weapon_index]
		guns[new_weapon][0].show()
		current_weapon = new_weapon
		
		Multiplayer.change_weapon(current_weapon)	
		
		default_ammo = guns[current_weapon][1]
		ammo = guns[current_weapon][2]
		shoot_cooldown.wait_time = guns[current_weapon][5]
		reload_time = guns[current_weapon][6]
		reload_cooldown.wait_time = reload_time
		max_ammo_label.text = str(default_ammo)
		current_ammo_label.text = str(ammo)
		
		max_ammo_label.text = str(default_ammo)
		
		guns[current_weapon][0].transform.origin.y -= 1
		guns[current_weapon][0].rotation_degrees.x += 70
		
		weapon_index_changed = false


func process_movement(delta):
	if (is_on_floor() or is_on_wall()) and fall_damage != 0:
		var fall_transform = Transform(vel.normalized(), global_transform.origin)
		if Multiplayer.connected:
			self_hit(fall_damage, fall_transform, 0)
		else:
			self_hit(fall_damage, fall_transform, 0)
		fall_damage = 0
		
	dir.y = 0
	dir = dir.normalized()
	
	vel.y += delta * GRAVITY
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir
	
	target *= MAX_SPEED
	
	var accel
	if dir.dot(hvel) > 0:
		if is_on_floor():
			accel = ACCEL
		else:
			accel = AIR_ACCEL
	else:
		if is_on_floor():
			accel = DEACCEL
		else:
			accel = AIR_DEACCEL
	
	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE), false)

	if vel.y < -30:
		fall_damage = round(-vel.y * fall_damage_factor)


func shoot_cooldown():
	can_shoot = true
	if Input.is_action_pressed("shoot") and guns[current_weapon][4]:
		guns[current_weapon][0].shoot() 


func reload_cooldown():
	reloading = false
	ammo = default_ammo
	current_ammo_label.text = str(ammo)


func die(bullet_global_transform, id):
	if not Multiplayer.dead:
		if guns[current_weapon][3] and is_scoping:
			unscope()
		Multiplayer.die(global_transform.origin, rotation, bullet_global_transform, id)
		emit_signal("died")
		is_spectating = true
		IngameUI.show_death_screen(id, DEATH_SCREEN_LENGTH)
		spawn() # Set position to random spawn point. This does NOT respawn the player.
		hide()
		yield(get_tree().create_timer(DEATH_SCREEN_LENGTH), "timeout")
		is_spectating = false
		show()
		spawn()
		Multiplayer.player_respawn(id)
		health = MAX_HEALTH
		ammo = default_ammo
		emit_signal("health_changed", health)


func spawn():
	var spawn_points = map.get_node("SpawnPoints").get_children()
	global_transform.origin = spawn_points[randi() % spawn_points.size()].global_transform.origin


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * mouse_sensitivity_multiplier))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1 * mouse_sensitivity_multiplier))
	
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -80, 80)
		rotation_helper.rotation_degrees = camera_rot
	
	if Input.is_action_just_pressed("reload") and not is_spectating and not IngameUI.paused:
		reloading = true
		reload_cooldown.start()
		guns[current_weapon][0].get_node("reload").play()
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				current_weapon_index += 1
				if current_weapon_index > guns.size() - 1:
					current_weapon_index = 0
				weapon_index_changed = true
			elif event.button_index == BUTTON_WHEEL_DOWN:
				current_weapon_index -= 1
				if current_weapon_index < 0:
					current_weapon_index = guns.size() - 1
				weapon_index_changed = true
	
	if Input.is_action_just_pressed("weapon_1"):
		current_weapon_index = 0
		weapon_index_changed = true
	elif Input.is_action_just_pressed("weapon_2"):
		current_weapon_index = 1
		weapon_index_changed = true
	elif Input.is_action_just_pressed("weapon_3"):
		current_weapon_index = 2
		weapon_index_changed = true


func unscope():
	IngameUI.hide_scope()
	guns[current_weapon][0].show()
	is_scoping = false


func scope():
	guns[current_weapon][0].hide()
	IngameUI.show_scope()
	is_scoping = true
