extends "res://models/MRX22-ReconFlyer/ReconFlyer.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _control(delta):
	
	
	# Rotation
	
	var rot = get_rotation()
	rot.x = 0
	rot.z = 0
	
	if(Input.is_action_pressed("turn_right")):
		rot += Vector3(0, -1, 0) * rotation_speed * delta
	
	if(Input.is_action_pressed("turn_left")):
		rot += Vector3(0,  1, 0) * rotation_speed * delta
	
	set_rotation(rot)
	
	
	# Move
	
	move_target = Vector3()
	
	if Input.is_action_pressed("forward"):
		move_target = Vector3(0, 0, -1).rotated(Vector3(0, 1, 0), rot.y)
	
	if Input.is_action_pressed("back"):
		move_target = Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), rot.y)
	
	var cam_xform = $Camera.global_transform
	
	var xVal = Input.get_joy_axis(0, 0)
	if xVal != 0:
		#_is_moving = true
		move_target += xVal * cam_xform.basis[0]
	
	var yVal = Input.get_joy_axis(0, 1)
	if yVal != 0:
		#_is_moving = true
		move_target += yVal * cam_xform.basis[2]
	
	
	move_target.y = 0
	
	move_target = move_target.normalized() * max_speed
	


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
