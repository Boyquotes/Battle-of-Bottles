extends ColorRect


signal finished


func _ready():
	$fade.connect("animation_finished", self, "_finished")


func fade_in():
	show()
	$fade.play("fade_in")
	yield(get_tree().create_timer(0.5), "timeout")
	hide()


func fade_out():
	show()
	$fade.play("fade_out")
	yield(get_tree().create_timer(0.5), "timeout")
	hide()


func _finished(arg):
	if arg == "fade_out":
		emit_signal("finished")
