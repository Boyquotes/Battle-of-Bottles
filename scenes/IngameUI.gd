extends Control

signal respawn

const PLAYER_ITEM = preload("res://scenes/PlayerListItem.tscn")

var paused = false
var death_screen_duration = 0
var animated_pause_menu_alpha = 0
var animated_scope_alpha = 0
var animated_health = 0
var show_cooldown = false

onready var bar = $health/HealthBar
onready var tween = $Tween
onready var health_max = $health/max
onready var health_current = $health/current
onready var damage_indicator = $crosshair/damage_indicator
onready var respawning_text = $death_ui/VBoxContainer/CenterContainer/respawning_text
onready var respawn_timer = $death_ui/respawn_timer
onready var shoot_cooldown: Timer = get_parent().get_node("shoot_cooldown")
onready var cooldown_bar = $crosshair/cooldown
onready var pause_menu_tween = $pause_menu/Tween
onready var pause_menu_main = $pause_menu/ingame_menu
onready var pause_menu_settings = $pause_menu/ingame_settings
onready var mouse_sensitivity_settings = $pause_menu/mouse_sensitivity_settings
onready var mouse_sensitivity_text = $pause_menu/mouse_sensitivity_settings/VBoxContainer/HBoxContainer2/HBoxContainer/MouseSensitivity
onready var mouse_sensitivity_warning = $pause_menu/mouse_sensitivity_settings/VBoxContainer/warning
onready var mouse_sensitivity_warning_value = $pause_menu/mouse_sensitivity_settings/VBoxContainer/invalid_value
onready var list_item_container = $pause_menu/ingame_menu/HBoxContainer/OtherPlayers/VBoxContainer
onready var minimap_texture = $minimap/rotation_helper/mask/map_texture
onready var minimap_rotation_helper = $minimap/rotation_helper
onready var minimap = $minimap


func _ready():
	var player_max_health = get_parent().MAX_HEALTH
	health_max.text = str(round(player_max_health / 10))
	update_health(player_max_health)
	get_parent().connect("health_changed", self, "_health_changed")
	get_parent().connect("hit", self, "_indicate_hit")
	shoot_cooldown.connect("timeout", self, "on_shoot_cooldown_timeout")

func _process(delta):
	bar.value = round(animated_health)
	if $crosshair/damage_indicator/Sprite.modulate != Color(1,1,1,0):
		$crosshair/damage_indicator/Sprite.modulate.a = clamp($crosshair/damage_indicator/Sprite.modulate.a - delta * 2, 0, 1)
		$crosshair/damage_indicator/Sprite.modulate.g = clamp($crosshair/damage_indicator/Sprite.modulate.g + delta, 0, 1)
		$crosshair/damage_indicator/Sprite.modulate.b = clamp($crosshair/damage_indicator/Sprite.modulate.b + delta, 0, 1)
	$Scope.modulate.a = animated_scope_alpha
	$pause_menu.modulate.a = animated_pause_menu_alpha
	if $pause_menu.modulate.a == 0:
		$pause_menu.hide()
	else:
		$pause_menu.show()
	
	if show_cooldown:
		cooldown_bar.value = shoot_cooldown.time_left

func start_cooldown():
	if shoot_cooldown.wait_time > 0.2:
		cooldown_bar.show()
		print("show")
		cooldown_bar.max_value = shoot_cooldown.wait_time
		show_cooldown = true

func on_shoot_cooldown_timeout():
	cooldown_bar.hide()
	show_cooldown = false

func _health_changed(health):
	update_health(health)

func _indicate_hit(bullet_transform: Transform):
	if not bullet_transform.origin == get_parent().global_transform.origin:
		$crosshair/rotation_helper.look_at_from_position(get_parent().global_transform.origin, bullet_transform.origin, Vector3.UP)
	damage_indicator.rotation_degrees = ($crosshair/rotation_helper.rotation_degrees.y - get_parent().rotation_degrees.y + 180) * -1
	$crosshair/damage_indicator/Sprite.modulate.a = clamp($crosshair/damage_indicator/Sprite.modulate.a + 0.4, 0, 0.8)
	$crosshair/damage_indicator/Sprite.modulate.g = clamp($crosshair/damage_indicator/Sprite.modulate.g - 0.3, 0, 1)
	$crosshair/damage_indicator/Sprite.modulate.b = clamp($crosshair/damage_indicator/Sprite.modulate.b - 0.3, 0, 1)

func update_health(new_value):
	health_current.text = str(round(new_value / 10))
	tween.interpolate_property(self, "animated_health", animated_health, new_value, 0.05)
	if not tween.is_active():
		tween.start()

func show_death_screen(player_id, duration):
	$MarginContainer.hide()
	$ammo.hide()
	$crosshair.hide()
	$death_ui.show()
	if Multiplayer.connected:
		if player_id == get_tree().get_network_unique_id():
			$death_ui/VBoxContainer2/CenterContainer3/username.text = "You died."
			$death_ui/VBoxContainer2/CenterContainer2/title.text = ""
		else:
			$death_ui/VBoxContainer2/CenterContainer3/username.text = Multiplayer.get_username_from_id(player_id)
	else:
		$death_ui/VBoxContainer2/CenterContainer3/username.text = "You died."
		$death_ui/VBoxContainer2/CenterContainer2/title.text = ""
	respawning_text.text = "Respawning in " + str(duration) + "..."
	death_screen_duration = duration
	respawn_timer.start()
	#while duration != 0:
	#	yield(get_tree().create_timer(1.0), "timeout")
	#	duration -= 1
	#	respawning_text.text = "Respawning in " + str(duration) + "..."
	#emit_signal("respawn")
	#$MarginContainer.show()
	#$ammo.show()
	#$crosshair.show()
	#$death_ui.hide()

func _on_respawn_timer_timeout():
	death_screen_duration -= 1
	respawning_text.text = "Respawning in " + str(death_screen_duration) + "..."
	if death_screen_duration != 0:
		respawn_timer.start()
	else:
		emit_signal("respawn")
		$MarginContainer.show()
		$ammo.show()
		$crosshair.show()
		$death_ui.hide()

func show_scope():
	#var tween2 = Tween.new()
	$Scope.show()
	tween.interpolate_property(self, "animated_scope_alpha", 0, 1, 0.5)
	if not tween.is_active():
		tween.start()

func hide_scope():
	tween.interpolate_property(self, "animated_scope_alpha", 1, 0, 0.5)
	if not tween.is_active():
		tween.start()

func _on_Disconnect_pressed():
	Multiplayer.stop_multiplayer()
	get_tree().change_scene("res://Menu.tscn")

func show_pause_menu():
	pause_menu_settings.hide()
	pause_menu_main.show()
	mouse_sensitivity_settings.hide()
	for i in list_item_container.get_children():
		i.queue_free()
	var players = Multiplayer.player_info
	var own_item = PLAYER_ITEM.instance()
	own_item.player_name = "You"
	own_item.kills = Multiplayer.kills
	own_item.deaths = Multiplayer.deaths
	list_item_container.add_child(own_item)
	for i in players.keys():
		if not(i == 1 and players[i]["info"]["name"] == "_server"):
			var item = PLAYER_ITEM.instance()
			item.id = i
			item.player_name = players[i]["info"]["name"]
			item.kills = players[i]["stats"][0]
			item.deaths = players[i]["stats"][1]
			if Multiplayer.is_server:
				item.is_kickable = true
			list_item_container.add_child(item)
		
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	paused = true
	pause_menu_tween.interpolate_property(self, "animated_pause_menu_alpha", 0, 1, 0.25)
	if not pause_menu_tween.is_active():
		pause_menu_tween.start()

func hide_pause_menu():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	paused = false
	pause_menu_tween.interpolate_property(self, "animated_pause_menu_alpha", 1, 0, 0.25)
	if not pause_menu_tween.is_active():
		pause_menu_tween.start() 

func _on_Continue_pressed():
	hide_pause_menu()

func toggle_minimap(i: bool):
	minimap.visible = i

func update_minimap(minimap_pos :Vector2, minimap_rot :float):
	#minimap_texture.position = Vector2(clamp(minimap_pos.x * 450 * 2 , -450, 450), clamp(minimap_pos.y * 470 * 2, -470, 470))
	minimap_texture.position = Vector2(minimap_pos.x * 450, minimap_pos.y * 470)
	minimap_rotation_helper.rotation_degrees = minimap_rot

func _on_Settings_pressed():
	pause_menu_main.hide()
	pause_menu_settings.show()

func _on_Back_pressed():
	pause_menu_settings.hide()
	pause_menu_main.show()

func _on_MouseSensitivity_pressed():
	pause_menu_settings.hide()
	mouse_sensitivity_settings.show()
	mouse_sensitivity_warning.hide()
	mouse_sensitivity_warning_value.hide()
	mouse_sensitivity_text.text = str(float(get_parent().mouse_sensitivity_multiplier))

func _on_left_pressed():
	if mouse_sensitivity_text.text.is_valid_float():
		mouse_sensitivity_text.text = str(float(mouse_sensitivity_text.text) - 0.1)

func _on_right_pressed():
	if mouse_sensitivity_text.text.is_valid_float():
		mouse_sensitivity_text.text = str(float(mouse_sensitivity_text.text) + 0.1)

func _on_Cancel_pressed():
	pause_menu_settings.show()
	mouse_sensitivity_settings.hide()

func _on_Apply_pressed():
	if mouse_sensitivity_text.text.is_valid_float():
		if float(mouse_sensitivity_text.text) < 0 or float(mouse_sensitivity_text.text) > 10:
			mouse_sensitivity_warning_value.show()
		else:
			get_parent().mouse_sensitivity_multiplier = float(mouse_sensitivity_text.text)
			pause_menu_settings.show()
			mouse_sensitivity_settings.hide()
			Global.settings["mouse_sensitivity"] = float(get_parent().mouse_sensitivity_multiplier)
			Global.save_settings()
	else:
		mouse_sensitivity_warning.show()
