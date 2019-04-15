extends HBoxContainer

export (bool) var show_millis = true

var time setget set_time

func set_time(value):
	time = int(value)
	
	var millisonds = time % 1000
	var seconds = int(time / 1000) % 60
	var minutes = (int(time / 1000)-seconds) / 60
	
	if show_millis:
		var format_string = "%02d:%02d:%02d"
		$Value.text = format_string % [minutes, seconds, millisonds]
	else:
		var format_string = "%02d:%02d"
		$Value.text = format_string % [minutes, seconds]

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
