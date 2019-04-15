extends Control



signal join

var room_name setget set_room_name

var host

var port


func set_room_name(newName):
	
	room_name = newName
	
	$MarginContainer/Control/Name.text = room_name
	

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Button_pressed():
	
	print("_on_Button_pressed")
	
	emit_signal("join", host, port)
	
	
