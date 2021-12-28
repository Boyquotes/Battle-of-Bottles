extends Control


const CONNECTING_TEXT = "Connecting to server..."
const LOADING_SPINNER_SPEED = 400
const BACKGROUND_LOADING = true

onready var loading_text = $MarginContainer/VBoxContainer/loading_text
onready var loading_spinner = $loading_anchor/loading_spinner


func _ready():
	loading_text.text = CONNECTING_TEXT
	Multiplayer.connect("loading_map", self, "on_multiplayer_loading_map")
	Multiplayer.activate_multiplayer(Global.IP)


func on_multiplayer_loading_map(map_name):
	loading_text.text = "Loading map " + str(map_name) + "..."
	if BACKGROUND_LOADING:
		BackgroundLoader.load_scene(Multiplayer.maps[map_name][1])
	else:
		yield(get_tree(), "idle_frame")
		get_tree().change_scene_to(load(Multiplayer.maps[map_name][1]))


func _process(delta):
	loading_spinner.rotation_degrees += delta * LOADING_SPINNER_SPEED


func _on_connection_timeout_timeout():
	if loading_text.text == CONNECTING_TEXT:
		# Connection timeout
		get_tree().network_peer = null
		get_tree().change_scene("res://scenes/ConnectionFailed.tscn")
