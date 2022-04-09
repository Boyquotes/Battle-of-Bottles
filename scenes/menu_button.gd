extends Panel
tool


signal pressed

export var text : String = "Button"

onready var button = $button
onready var label = $Label


func _ready():
	label.text = text


func _on_button_pressed():
	emit_signal("pressed")
