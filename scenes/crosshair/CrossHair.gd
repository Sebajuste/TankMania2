extends Node

var default_mouse_cursor = load("res://mouse_cursor.png")

var target_search = load("res://scenes/crosshair/target_search.png")
var target_locked = load("res://scenes/crosshair/target_locked.png")


var _previous_lock = false

func set_target_lock(locked):
	
	if _previous_lock == locked:
		return
	
	if locked:
		Input.set_custom_mouse_cursor(target_locked)
	else:
		Input.set_custom_mouse_cursor(target_search)
	_previous_lock = locked

func reset():
	
	Input.set_custom_mouse_cursor(target_search)
	_previous_lock = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	Input.set_custom_mouse_cursor(target_search)
	
	pass

#func _exit_tree():
#    Input.set_custom_mouse_cursor(default_mouse_cursor)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
