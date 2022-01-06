extends Control


const CAMERA_SHAKE_SPEED = 35
const CAMERA_SHAKE_INTENSITY = 0.01

var noise = OpenSimplexNoise.new()
var customizing = false

var current_index = 0
var bottle_index = 0

var current_bottle
var current_hat

onready var menu_main = $menu_main
onready var menu_play = $menu_play
onready var menu_server_ip = $menu_server_ip
onready var menu_host = $menu_host_server
onready var menu_settings = $menu_settings
onready var menu_customization = $menu_customization
onready var menu_mods = $menu_mods
onready var camera_3d = $"3D/rotation_helper/Camera"
onready var customization_animation = $"3D/rotation_helper/animation"
onready var customization_character = $"3D/customization_player"
onready var customization_title = $menu_customization/VBoxContainer/Label
onready var username_edit = $menu_settings/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username_blur/Username
onready var server_ip_line = $menu_server_ip/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/server_ip_blur/Server_IP
onready var max_players = $menu_host_server/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/MaxPlayers_blur
onready var map_selection = $menu_host_server/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Map_blur
onready var mods_list = $menu_mods/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/list_blur/list_darken/ScrollContainer/mods_list
onready var mods_warning = $menu_mods/warning
onready var camera_start_pos = camera_3d.global_transform.origin
onready var custs: Dictionary = customization_character.customizations
onready var local_server_ip = $menu_host_server/Control/server_ip


func _ready():
	$Black.fade_in()
	menu_main.show()
	menu_server_ip.hide()
	menu_settings.hide()
	menu_customization.hide()
	menu_play.hide()
	
	noise.seed = randf()
	current_bottle = Global.user_customization["bottles"]
	current_hat = Global.user_customization["hats"]
	
	$"3D/KinematicBody".customize(Global.user_customization)
	customization_character.customize(Global.user_customization)
	
	if custs["hats"].has(current_hat):
		customization_title.text = custs["hats"][current_hat][0]
	
	if Global.settings != null and Global.settings.has("username"):
		username_edit.text = Global.settings["username"]
	
	if Global.settings.has("last_server"):
		if Global.settings["last_server"] != "none":
			server_ip_line.text = Global.settings["last_server"]
	
	var local_ip_address := ""
	for address in IP.get_local_addresses():
		if (address.split('.').size() == 4):
			if address.split('.')[0].length() == 3:
				local_ip_address = address
	if local_ip_address != "":
		local_server_ip.text = "Local Server IP: %s" % local_ip_address
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_Play_pressed():
	menu_main.hide()
	menu_play.show()


func _on_Quit_pressed():
	get_tree().quit()


func _on_Connect_pressed():
	if server_ip_line.text != "":
		var ip_text = server_ip_line.text
		if ip_text.count(":") == 1:
			# Custom port
			var ip_port = ip_text.split(":", false, 1)
			if ip_port[1].is_valid_integer():
				Global.IP = ip_port[0]
				Global.port = int(ip_port[1])
				Global.settings["last_server"] = server_ip_line.text
				Global.save_settings()
				get_tree().change_scene("res://scenes/LoadMap.tscn")
			else:
				Global.IP = server_ip_line.text
				Global.port = 0
				Global.settings["last_server"] = server_ip_line.text
				Global.save_settings()
				get_tree().change_scene("res://scenes/LoadMap.tscn")
		else:
			Global.IP = server_ip_line.text
			Global.port = 0
			Global.settings["last_server"] = server_ip_line.text
			Global.save_settings()
			get_tree().change_scene("res://scenes/LoadMap.tscn")


var t = 0
func _process(delta):
	t += delta
	camera_3d.global_transform.origin.x = camera_start_pos.x + noise.get_noise_3d(t * CAMERA_SHAKE_SPEED, 0, 0) * CAMERA_SHAKE_INTENSITY * 10
	camera_3d.global_transform.origin.y = camera_start_pos.y + noise.get_noise_3d(0, t * CAMERA_SHAKE_SPEED, 0) * CAMERA_SHAKE_INTENSITY * 10
	camera_3d.global_transform.origin.z = camera_start_pos.z + noise.get_noise_3d(0, 0, t * CAMERA_SHAKE_SPEED) * CAMERA_SHAKE_INTENSITY * 10
	if customizing:
		$"3D/customization_player".rotation_degrees.y -= delta * 360 * 0.075


func _on_Back_pressed():
	menu_play.show()
	menu_server_ip.hide()


func _on_Settings_pressed():
	menu_main.hide()
	menu_settings.show()


func _on_BackSettings_pressed():
	menu_main.show()
	menu_settings.hide()
	Global.settings["username"] = username_edit.text
	Global.save_settings()


func _on_Customize_pressed():
	customizing = true
	$"3D/customization_player".rotation_degrees.y = 0
	customization_character.customization_reset()
	customization_character.customize(Global.user_customization)
	
	current_index = custs["hats"].keys().find(current_hat)
	bottle_index = custs["bottles"].keys().find(current_bottle)
	if custs["hats"].has(current_hat):
		customization_title.text = custs["hats"][current_hat][0]
	customization_animation.play("right")
	menu_main.hide()
	menu_customization.show()


func _on_CancelCustomization_pressed():
	current_hat = Global.user_customization["hats"]
	current_bottle = Global.user_customization["bottles"]
	customization_animation.play_backwards("right")
	menu_main.show()
	menu_customization.hide()


func _on_left_cust_pressed():
	current_index -= 1
	if current_index < 0:
		current_index = custs["hats"].size() - 1
	update_hats(current_index)


func _on_right_cust_pressed():
	current_index += 1
	if current_index > custs["hats"].size() - 1:
		current_index = 0
	update_hats(current_index)


func _on_Apply_pressed():
	Global.user_customization = {
	"hats": current_hat,
	"bottles": current_bottle
	}
	$"3D/KinematicBody".customization_reset()
	$"3D/KinematicBody".customize(Global.user_customization)
	customization_animation.play_backwards("right")
	menu_main.show()
	menu_customization.hide()
	Global.save_customizations()


func _on_left_bottle_pressed():
	bottle_index -= 1
	if bottle_index < 0:
		bottle_index = custs["bottles"].size() - 1
	update_bottle(bottle_index)


func _on_right_bottle_pressed():
	bottle_index += 1
	if bottle_index > custs["bottles"].size() - 1:
		bottle_index = 0
	update_bottle(bottle_index)


func update_bottle(index):
	current_bottle = custs["bottles"].keys()[index]
	var own_customization = {
	"hats": current_hat,
	"bottles": current_bottle
	}
	customization_character.customization_reset()
	customization_character.customize(own_customization)


func update_hats(index):
	current_hat = custs["hats"].keys()[index]
	var own_customization = {
	"hats": current_hat,
	"bottles": current_bottle
	}
	customization_title.text = custs["hats"][current_hat][0]
	customization_character.customization_reset()
	customization_character.customize(own_customization)


func _on_ToggleFullscreen_pressed():
	OS.window_fullscreen = !OS.window_fullscreen
	if Global.settings.has("fullscreen"):
		Global.settings["fullscreen"] = OS.window_fullscreen
		Global.save_settings()
	else:
		Global.reset_settings()
		Global.settings["fullscreen"] = OS.window_fullscreen
		Global.save_settings()


func _on_Join_pressed():
	menu_play.hide()
	menu_server_ip.show()


func _on_PlayHost_pressed():
	menu_play.hide()
	menu_host.show()


func _on_Host_pressed():
	if int(max_players.edit.text) < 0:
		Global.max_players = 2
	else:
		Global.max_players = int(max_players.edit.text)
	Global.map = map_selection.current_map
	get_tree().change_scene("res://scenes/HostGame.tscn")


func _on_BackHost_pressed():
	menu_host.hide()
	menu_play.show()


func _on_BackPlay_pressed():
	menu_play.hide()
	menu_main.show()


func _on_BackMods_pressed():
	menu_settings.show()
	menu_mods.hide()


func _on_Mods_pressed():
	menu_settings.hide()
	menu_mods.show()
	menu_mods.show_mods()
