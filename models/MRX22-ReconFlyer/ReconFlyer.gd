extends KinematicBody

export (float) var ACCEL= 4
export (float) var DEACCEL= 2

export (float) var max_speed = 20
export (float) var rotation_speed  = 1

export (int) var max_health = 10



var velocity = Vector3()
var move_target = Vector3()

var alive = true


func _control(delta):
	pass

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _physics_process(delta):
	
	if not alive:
		return
	
	_control(delta)
	
	# Move
	
	#velocity.y += delta
	
	var hvel = velocity
	hvel.y = 0
	
	var accel = DEACCEL
	if move_target.dot(hvel) > 0:
		accel = ACCEL
	
	hvel = hvel.linear_interpolate(move_target, accel * delta)
	
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
	
