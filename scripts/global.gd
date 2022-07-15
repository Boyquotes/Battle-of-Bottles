extends Node


const default_settings = {
	"username": "Player",
	"last_server": "none",
	"fullscreen": false,
	"mouse_sensitivity": 1.0,
	"active_mods" : []
}

const customizations = {
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
		"default_bottle": ["Default", "Boooring!", preload("res://assets/customizations/DefaultBottle.tscn"), preload("res://assets/customizations/DefaultBottle_broken.tscn")],
		"ketchup_bottle": ["\"Ketchup\"", "It's ketchup, nothing else.", preload("res://assets/customizations/KetchupBottle.tscn"), preload("res://assets/customizations/KetchupBottle_broken.tscn")],
		"superbottle": ["Superbottle", "Is it a bird? Is it a plane? No, it's Superbottle!", preload("res://assets/customizations/SuperBottle.tscn"), preload("res://assets/customizations/SuperBottle_broken.tscn")],
		"cyberbottle": ["CYBERBOTTLE", "(almost) unbreakable.", preload("res://assets/customizations/CyberBottle.tscn"), preload("res://assets/customizations/CyberBottle_broken.tscn")],
		"suitbottle": ["Suit Bottle", "Nothin' suits me like a suit!", preload("res://assets/customizations/SuitBottle.tscn"), preload("res://assets/customizations/SuitBottle_broken.tscn")],
	}
}

const SAVE_PATH_CUSTOMIZATIONS = "user://customizations.dat"
const SAVE_PATH_SETTINGS = "user://settings.json"

var settings = default_settings

var IP
var port := 0
var current_scene
var root

var max_players: int
var map: String
var required_mods: Array

var user_customization = {"bottles": "default_bottle", "hats": "hat"}


func _ready():
	load_customizations()
	load_settings()
	
	root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	if settings.has("fullscreen"):
		OS.window_fullscreen = settings["fullscreen"]


func _input(event):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
		if settings.has("fullscreen"):
			settings["fullscreen"] = OS.window_fullscreen
			save_settings()


func reset_settings():
	settings = default_settings
	save_settings()


func load_settings():
	var file = File.new()
	if file.file_exists(SAVE_PATH_SETTINGS):
		file.open(SAVE_PATH_SETTINGS, File.READ)
		var raw_data = file.get_as_text()
		settings = parse_json(raw_data)
		if settings == null:
			settings = {}


func save_settings():
	var file = File.new()
	file.open(SAVE_PATH_SETTINGS, File.WRITE)
	file.store_string(to_json(settings))
	file.close()


func load_customizations():
	var file = File.new()
	if file.file_exists(SAVE_PATH_CUSTOMIZATIONS):
		file.open(SAVE_PATH_CUSTOMIZATIONS, File.READ)
		var customizations = file.get_var()
		file.close()
		user_customization = customizations


func save_customizations():
	var file = File.new()
	file.open(SAVE_PATH_CUSTOMIZATIONS, File.WRITE)
	file.store_var(user_customization)
	file.close()


func goto_scene(path):
	current_scene = root.get_child(root.get_child_count() - 1)
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instance()

	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)
