extends Control

signal restarted

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _input(event):
	
	if visible and event is InputEventKey and event.scancode == KEY_ENTER and event.pressed:
		emit_signal("restarted")
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
