extends Control


const LOADING_SPINNER_SPEED = 400

onready var loading_spinner = $loading_anchor/loading_spinner


func _ready():
	if Multiplayer.host_game(Global.max_players, Global.map) != 0:
		Multiplayer.connection_failed()


func _process(delta):
	loading_spinner.rotation_degrees += delta * LOADING_SPINNER_SPEED
